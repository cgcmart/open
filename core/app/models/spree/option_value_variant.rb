# frozen_string_literal: true

module Spree
  class OptionValueVariant < Spree::Base
    belongs_to :option_value
    belongs_to :variant
  end
end
