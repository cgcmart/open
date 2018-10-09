# frozen_string_literal: true

module Spree
  class TaxonImage < Asset
    include Configuration::ActiveStorage
  end
end
