# frozen_string_literal: true

module Spree
  class Payment
    # Payment cancellation handler
    #
    # Cancels a payment by trying to void first and if that fails
    # creating a refund about the full amount instead.
    #
    class Cancellation
      DEFAULT_REASON = 'Order canceled'.freeze

      attr_reader :reason

      # @param reason [String] (DEFAULT_REASON) -
      #   The reason used to create the Spree::RefundReason
      def initialize(reason: DEFAULT_REASON)
        @reason = reason
      end

      private

      def refund_reason
        Spree::RefundReason.where(name: reason).first_or_create
      end

      def try_void_available?(payment_method)
        payment_method.respond_to?(:try_void) &&
          payment_method.method(:try_void).owner != Spree::PaymentMethod
      end
    end
  end
end
