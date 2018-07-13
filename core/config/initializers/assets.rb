# frozen_string_literal: true

if Rails.application.config.respond_to?(:assets)
  Rails.application.config.assets.precompile << 'spree_core_manifest.js'
end
