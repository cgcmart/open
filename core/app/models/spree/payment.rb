# frozen_string_literal: true

module Spree
  class Payment < Spree::Base
    include Spree::Payment::Processing

    NON_RISKY_AVS_CODES = ['B', 'D', 'H', 'J', 'M', 'Q', 'T', 'V', 'X', 'Y'].freeze
    RISKY_AVS_CODES     = ['A', 'C', 'E', 'F', 'G', 'I', 'K', 'L', 'N', 'O', 'P', 'R', 'S', 'U', 'W', 'Z'].freeze

    belongs_to :order, class_name: 'Spree::Order', touch: true, inverse_of: :payments
    belongs_to :source, polymorphic: true
    belongs_to :payment_method, -> { with_deleted }, class_name: 'Spree::PaymentMethod', inverse_of: :payments

    has_many :offsets, -> { offset_payment }, class_name: 'Spree::Payment', foreign_key: :source_id
    has_many :log_entries, as: :source
    has_many :state_changes, as: :stateful
    has_many :capture_events, class_name: 'Spree::PaymentCaptureEvent'
    has_many :refunds, inverse_of: :payment

    before_validation :validate_source, unless: :invalid?
    before_create :set_unique_identifier

    after_save :create_payment_profile, if: :profiles_supported?

    # update the order totals, etc.
    after_save :update_order

    after_create :create_eligible_credit_event

    # invalidate previously entered payments
    after_create :invalidate_old_payments

    attr_accessor :request_env

    validates :amount, numericality: true
    validates :source, presence: true, if: :source_required?
    validates :payment_method, presence: true

    delegate :name, to: :payment_method, allow_nil: true, prefix: true
    default_scope -> { order(:created_at) }

    scope :from_credit_card, -> { where(source_type: 'Spree::CreditCard') }
    scope :with_state, ->(s) { where(state: s.to_s) }
    # "offset" is reserved by activerecord
    scope :offset_payment, -> { where("source_type = 'Spree::Payment' AND amount < 0 AND state = 'completed'") }

    scope :checkout, -> { with_state('checkout') }
    scope :completed, -> { with_state('completed') }
    scope :pending, -> { with_state('pending') }
    scope :processing, -> { with_state('processing') }
    scope :failed, -> { with_state('failed') }

    scope :risky, -> { where("avs_response IN (?) OR (cvv_response_code IS NOT NULL and cvv_response_code != 'M') OR state = 'failed'", RISKY_AVS_CODES) }
    scope :valid, -> { where.not(state: INVALID_STATES) }

    scope :store_credits, -> { where(source_type: Spree::StoreCredit.to_s) }
    scope :not_store_credits, -> { where(arel_table[:source_type].not_eq(Spree::StoreCredit.to_s).or(arel_table[:source_type].eq(nil))) }

    # order state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :checkout do
      # With card payments, happens before purchase or authorization happens
      #
      # Setting it after creating a profile and authorizing a full amount will
      # prevent the payment from being authorized again once Order transitions
      # to complete
      event :started_processing do
        transition from: [:checkout, :pending, :completed, :processing], to: :processing
      end
      # When processing during checkout fails
      event :failure do
        transition from: [:pending, :processing], to: :failed
      end
      # With card payments this represents authorizing the payment
      event :pend do
        transition from: [:checkout, :processing], to: :pending
      end
      # With card payments this represents completing a purchase or capture transaction
      event :complete do
        transition from: [:processing, :pending, :checkout], to: :completed
      end
      event :void do
        transition from: [:pending, :processing, :completed, :checkout], to: :void
      end
      # when the card brand isnt supported
      event :invalidate do
        transition from: [:checkout], to: :invalid
      end

      after_transition do |payment, transition|
        payment.state_changes.create!(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'payment'
        )
      end
    end

    # transaction_id is much easier to understand
    def transaction_id
      response_code
    end

    delegate :currency, to: :order

    def money
      Spree::Money.new(amount, { currency: currency })
    end
    alias display_amount money

    def amount=(amount)
      self[:amount] =
        case amount
        when String
          separator = I18n.t('number.currency.format.separator')
          number    = amount.delete("^0-9-#{separator}\.").tr(separator, '.')
          number.to_d if number.present?
        end || amount
    end

    def offsets_total
      offsets.pluck(:amount).sum
    end

    def credit_allowed
      amount - (offsets_total.abs + refunds.sum(:amount))
    end

    def can_credit?
      credit_allowed > 0
    end

    # @return [Boolean] true when this payment has been fully refunded
    def fully_refunded?
      refunds.map(&:amount).sum == amount
    end

    # @return [Array<String>] the actions available on this payment
    def actions
      sa = source_actions
      sa |= ["failure"] if processing?
      sa
    end

    def payment_source
      res = source.is_a?(Payment) ? source.source : source
      res || payment_method
    end

    def is_avs_risky?
      return false if avs_response.blank? || NON_RISKY_AVS_CODES.include?(avs_response)

      true
    end

    def is_cvv_risky?
      return false if cvv_response_code == 'M'
      return false if cvv_response_code.nil?
      return false if cvv_response_message.present?

      true
    end

    def captured_amount
      capture_events.sum(:amount)
    end

    def uncaptured_amount
      amount - captured_amount
    end

    # @return [Boolean] true when the payment method exists and is a store credit payment method
    def store_credit?
      payment_method.try!(:store_credit?)
    end

    private

    def source_actions
      return [] unless payment_source&.respond_to?(:actions)

      payment_source.actions.select { |action| !payment_source.respond_to?("can_#{action}?") || payment_source.send("can_#{action}?", self) }
    end

    def validate_source
      if source && !source.valid?
        source.errors.each do |field, error|
          field_name = I18n.t("activerecord.attributes.#{source.class.to_s.underscore}.#{field}")
          errors.add(I18n.t(source.class.to_s.demodulize.underscore, scope: 'spree'), "#{field_name} #{error}")
        end
      end
      if errors.any?
        throw :abort
      end
    end

    def source_required?
      payment_method.present? && payment_method.source_required?
    end

    def profiles_supported?
      payment_method.respond_to?(:payment_profiles_supported?) && payment_method.payment_profiles_supported?
    end

    def create_payment_profile
      # Don't attempt to create on bad payments.
      return if %w(invalid failed).include?(state)
      # Payment profile cannot be created without source
      return unless source
      # Imported payments shouldn't create a payment profile.
      return if source.imported

      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

    def invalidate_old_payments
      if !store_credit? && !['invalid', 'failed'].include?(state)
        order.payments.select { |payment|
          payment.state == 'checkout' && !payment.store_credit? && payment.id != id
        }.each(&:invalidate!)
      end
    end

    def update_order
      if order.completed? || completed? || void?
        order.recalculate
      end
    end

    # Necessary because some payment gateways will refuse payments with
    # duplicate IDs. We *were* using the Order number, but that's set once and
    # is unchanging. What we need is a unique identifier on a per-payment basis,
    # and this is it. Related to https://github.com/spree/spree/issues/1998.
    # See https://github.com/spree/spree/issues/1998#issuecomment-12869105
    def set_unique_identifier
      loop do
        self.number = generate_identifier
        break unless self.class.exists?(number: number)
      end
    end

    def generate_identifier
      Array.new(8){ IDENTIFIER_CHARS.sample }.join
    end

    def create_eligible_credit_event
      # When cancelling an order, a payment with the negative amount
      # of the payment total is created to refund the customer. That
      # payment has a source of itself (Spree::Payment) no matter the
      # type of payment getting refunded, hence the additional check
      # if the source is a store credit.
      if store_credit? && source.is_a?(Spree::StoreCredit)
        source.update_attributes!({
          action: Spree::StoreCredit::ELIGIBLE_ACTION,
          action_amount: amount,
          action_authorization_code: response_code
        })
      end
    end
  end
end
