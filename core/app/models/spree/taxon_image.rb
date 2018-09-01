# frozen_string_literal: true

module Spree
  class TaxonImage < Asset
    include Rails.application.config.use_paperclip ? Configuration::Paperclip : Configuration::ActiveStorage
  end
end
