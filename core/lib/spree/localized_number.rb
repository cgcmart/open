# frozen_string_literal: true

module Spree
  class LocalizedNumber
    # Strips all non-price-like characters from the number, taking into account locale settings.
    def self.parse(number)
      return number unless number.is_a?(String)

      separator = I18n.t(:'number.currency.format.separator')
      non_number_characters = /[^0-9\-#{separator}]/

      # strip everything else first
      number = number.gsub(non_number_characters, '')

      # then replace the locale-specific decimal separator with the standard separator if necessary
      number = number.gsub!(separator, '.') unless separator == '.'

      # Handle empty string for ruby 2.4 compatibility
      BigDecimal(number.presence || 0)
    end
  end
end
