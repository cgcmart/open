# frozen_string_literal: true

module Spree
  module Core
    module ControllerHelpers
      module Pricing
        extend ActiveSupport::Concern

        included do
          helper_method :current_pricing_options
        end

        def current_pricing_options
          Spree::Config.pricing_options_class.new(
            currency: current_store.try!(:default_currency).presence || Spree::Config[:currency],
            country_iso: current_store.try!(:cart_tax_country_iso).presence
          )
        end
      end
    end
  end
end
