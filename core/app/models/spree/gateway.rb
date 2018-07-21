# frozen_string_literal: true

module Spree
  class Gateway < PaymentMethod::CreditCard
    def initialize(*args)
      super
    end
  end
end
