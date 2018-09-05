# frozen_string_literal: true

require 'discard'
require 'spree/preferences/statically_configurable'

module Spree
  class PaymentMethod < Spree::Base
    acts_as_paranoid

    include Discard::Model
    self.discard_column = :deleted_at

    acts_as_list

   # @private
    def self.const_missing(name)
      if name == :DISPLAY
        const_set(:DISPLAY, [:both, :front_end, :back_end])
      else
        super
      end
    end

    validates :name, :type, presence: true

    has_many :payments, class_name: "Spree::Payment", inverse_of: :payment_method
    has_many :credit_cards, class_name: "Spree::CreditCard"
    has_many :store_payment_methods, inverse_of: :payment_method
    has_many :stores, through: :store_payment_methods

    scope :ordered_by_position, -> { order(:position) }
    scope :active,                 -> { where(active: true).order(position: :asc) }
    scope :available_to_users, -> { where(available_to_users: true) }
    scope :available_to_admin, -> { where(available_to_admin: true) }
    scope :available_to_store, ->(store) do
      raise ArgumentError, "You must provide a store" if store.nil?
      store.payment_methods.empty? ? all : where(id: store.payment_method_ids)
    end

    delegate :authorize, :purchase, :capture, :void, :credit, to: :gateway

    class ModelName < ActiveModel::Name
      # Similar to ActiveModel::Name#human, but skips lookup_ancestors
      def human(options = {})
        defaults = [
          i18n_key,
          options[:default],
          @human
        ].compact
        options = { scope: [:activerecord, :models], count: 1, default: defaults }.merge!(options.except(:default))
        I18n.translate(defaults.shift, options)
      end
    end

    class << self
      def payment_methods
        Rails.application.config.spree.payment_methods
      end

      def active
        display_on = display_on.to_s

        available_payment_methods =
          case display_on
          when 'front_end'
            active.available_to_users
          when 'back_end'
            active.available_to_admin
          else
            active.available_to_users.available_to_admin
          end
        available_payment_methods.select do |p|
          store.nil? || store.payment_methods.empty? || store.payment_methods.include?(p)
        end
      end

      def model_name
        ModelName.new(self, Spree)
      end

      def active.any?
        where(type: to_s, active: true).count > 0
      end

      def with_deleted.find(*args)
        unscoped { find(*args) }
      end
    end

    def gateway
      gateway_options = options
      gateway_options.delete :login if gateway_options.key?(:login) && gateway_options[:login].nil?
      if gateway_options[:server]
        ActiveMerchant::Billing::Base.mode = gateway_options[:server].to_sym
      end
      @gateway ||= gateway_class.new(gateway_options)
    end

    # Represents all preferences as a Hash
    #
    # Each preference is a key holding the value(s) and gets passed to the gateway via +gateway_options+
    #
    # @return Hash
    def options
      preferences.to_hash
    end

    # The class that will store payment sources (re)usable with this payment method
    #
    # Used by Spree::Payment as source (e.g. Spree::CreditCard in the case of a credit card payment method).
    #
    # Returning nil means the payment method doesn't support storing sources (e.g. Spree::PaymentMethod::Check)
    def payment_source_class
      raise ::NotImplementedError, 'You must implement payment_source_class method for #{self.class}.'
    end

    def method_type
      type.demodulize.downcase
    end

    def payment_profiles_supported?
      false
    end

    def source_required?
      true
    end

    # Custom gateways should redefine this method. See Gateway implementation
    # as an example
    def reusable_sources(_order)
      []
    end

    def auto_capture?
      auto_capture.nil? ? Spree::Config[:auto_capture] : auto_capture
    end

    def supports?(_source)
      true
    end

    def try_void(_payment)
      raise ::NotImplementedError,
        "You need to implement `try_void` for #{self.class.name}. In that " \
        'return a ActiveMerchant::Billing::Response object if the void succeeds '\
        'or `false|nil` if the void is not possible anymore. ' \
        'Spree will refund the amount of the payment then.'
    end

    def store_credit?
      self.class == Spree::PaymentMethod::StoreCredit
    end

    # Custom PaymentMethod/Gateway can redefine this method to check method
    # availability for concrete order.
    def available_for_order?(_order)
      true
    end
  end
end
