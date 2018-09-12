# frozen_string_literal: true

module Spree
  class BaseMailer < ActionMailer::Base
    def from_address(store)
      store.mail_from_address
    end

    def money(amount, currency = Spree::Config[:currency])
      Spree::Money.new(amount, currency: currency).to_s
    end
    helper_method :money

    def frontend_available?
      Spree::Core::Engine.frontend_available?
    end
    helper_method :frontend_available?

    def mail(headers = {}, &block)
      super if Spree::Config[:send_core_emails]
    end
  end
end
