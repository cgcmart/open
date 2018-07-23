# frozen_string_literal: true

module Spree
  module UserPaymentSource
    extend ActiveSupport::Concern

    def default_credit_card
      default = wallet.default_wallet_payment_source
      if default && default.payment_source.is_a?(Spree::CreditCard)
        default.payment_source
      end
    end

    def payment_sources
      credit_cards.with_payment_profile
    end
  end
end
