# frozen_string_literal: true

module Spree
  class CreditCard < Spree::PaymentSource
    if !ENV['SPREE_DISABLE_DB_CONNECTION'] &&
        connection.data_source_exists?(:spree_credit_cards) &&
        connection.column_exists?(:spree_credit_cards, :deleted_at)
      acts_as_paranoid
    end

    belongs_to :payment_method
    belongs_to :user, class_name: Spree::UserClassHandle.new, foreign_key: 'user_id',
    belongs_to :address

    before_save :set_last_digits

    accepts_nested_attributes_for :address

    attr_reader :number, :verification_value
    attr_accessor :encrypted_data

    validates :month, :year, numericality: { only_integer: true }, if: :require_card_numbers?, on: :create
    validates :number, presence: true, if: :require_card_numbers?, on: :create, unless: :imported
    validates :name, presence: true, if: :require_card_numbers?, on: :create
    validates :verification_value, presence: true, if: :require_card_numbers?, on: :create, unless: :imported

    scope :with_payment_profile, -> { where('gateway_customer_profile_id IS NOT NULL') }

    def self.default
      joins(:wallet_payment_sources).where(spree_wallet_payment_sources: { default: true })
    end

    # needed for some of the ActiveMerchant gateways (eg. SagePay)
    alias_attribute :brand, :cc_type

    # Taken from ActiveMerchant
    # https://github.com/activemerchant/active_merchant/blob/2f2acd4696e8de76057b5ed670b9aa022abc1187/lib/active_merchant/billing/credit_card_methods.rb#L5
    CARD_TYPES = {
      'visa'               => /^4\d{12}(\d{3})?(\d{3})?$/,
      'master'             => /^(5[1-5]\d{4}|677189|222[1-9]\d{2}|22[3-9]\d{3}|2[3-6]\d{4}|27[01]\d{3}|2720\d{2})\d{10}$/,
      'discover'           => /^(6011|65\d{2}|64[4-9]\d)\d{12}|(62\d{14})$/,
      'american_express'   => /^3[47]\d{13}$/,
      'diners_club'        => /^3(0[0-5]|[68]\d)\d{11}$/,
      'jcb'                => /^35(28|29|[3-8]\d)\d{12}$/,
      'switch'             => /^6759\d{12}(\d{2,3})?$/,
      'solo'               => /^6767\d{12}(\d{2,3})?$/,
      'dankort'            => /^5019\d{12}$/,
      'maestro'            => /^(5[06-8]|6\d)\d{10,17}$/,
      'forbrugsforeningen' => /^600722\d{10}$/,
      'laser'              => /^(6304|6706|6709|6771(?!89))\d{8}(\d{4}|\d{6,7})?$/
    }.freeze

    def default
      user.wallet.default_wallet_payment_source
      return false if user.nil?
      user.wallet.default_wallet_payment_source.try!(:payment_source) == self
    end

    def default=(set_as_default)
      user.wallet.default_wallet_payment_source
      if user.nil?
        raise "Cannot set 'default' on a credit card without a user"
      elsif set_as_default # setting this card as default
        wallet_payment_source = user.wallet.add(self)
        user.wallet.default_wallet_payment_source = wallet_payment_source
        true
      else # removing this card as default
        if user.wallet.default_wallet_payment_source.try!(:payment_source) == self
          user.wallet.default_wallet_payment_source = nil
        end
        false
      end
    end

    def address_attributes=(attributes)
      self.address = Spree::Address.immutable_merge(address, attributes)
    end

    # Sets the expiry date on this credit card.
    #
    # @param expiry [String] the desired new expiry date in one of the
    #   following formats: "mm/yy", "mm / yyyy", "mmyy", "mmyyyy"
    def expiry=(expiry)
      return unless expiry.present?

      self[:month], self[:year] =
        if expiry =~ /\d{2}\s?\/\s?\d{2,4}/ # will match mm/yy and mm / yyyy
          expiry.delete(' ').split('/')
        elsif match = expiry.match(/(\d{2})(\d{2,4})/) # will match mmyy and mmyyyy
          [match[1], match[2]]
        end
      if self[:year]
        self[:year] = "20#{self[:year]}" if self[:year].length == 2
        self[:year] = self[:year].to_i
      end
      self[:month] = self[:month].to_i if self[:month]
    end

    def number=(num)
      @number = begin
                  num.gsub(/[^0-9]/, '')
                rescue
                rescue StandardError
                  nil
                end
    end

    def verification_value=(value)
      @verification_value = value.to_s.gsub(/\s/, '')
    end

    # cc_type is set by jquery.payment, which helpfully provides different
    # types from Active Merchant. Converting them is necessary.
    def cc_type=(type)
      self[:cc_type] = case type
                       when 'mastercard', 'maestro' then 'master'
                       when 'amex' then 'american_express'
                       when 'dinersclub' then 'diners_club'
                       when '' then try_type_from_number
      else type
      end
    end

    def set_last_digits
      self.last_digits ||= number.to_s.length <= 4 ? number : number.to_s.slice(-4..-1)
    end

    def try_type_from_number
      CARD_TYPES.each do |type, pattern|
        return type if number =~ pattern
      end
      ''
    end

    def verification_value?
      verification_value.present?
    end

    # Show the card number, with all but last 4 numbers replace with "X". (XXXX-XXXX-XXXX-4338)
    def display_number
      "XXXX-XXXX-XXXX-#{last_digits}"
    end

    def reusable?
      has_payment_profile?
    end

    def has_payment_profile?
      gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
    end

    # ActiveMerchant needs first_name/last_name because we pass it a Spree::CreditCard and it calls those methods on it.
    # Looking at the ActiveMerchant source code we should probably be calling #to_active_merchant before passing
    # the object to ActiveMerchant but this should do for now.
    def first_name
      name.to_s.split(/[[:space:]]/, 2)[0]
    end

    def last_name
      name.to_s.split(/[[:space:]]/, 2)[1]
    end

    def to_active_merchant
      ActiveMerchant::Billing::CreditCard.new(
        number: number,
        month: month,
        year: year,
        verification_value: verification_value,
        first_name: first_name,
        last_name: last_name
      )
    end

    private

    def require_card_numbers?
      !encrypted_data.present? && !has_payment_profile?
    end
  end
end
