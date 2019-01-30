# frozen_string_literal: true

require 'spree/config'

module Spree
  module Core
    class Engine < ::Rails::Engine
      CREDIT_CARD_NUMBER_PARAM = /payment.*source.*\.number$/
      CREDIT_CARD_VERIFICATION_VALUE_PARAM = /payment.*source.*\.verification_value$/

      isolate_namespace Spree
      engine_name 'spree'

      config.generators do |g|
        g.test_framework :rspec
      end

      initializer 'spree.environment', before: :load_config_initializers do |app|
        app.config.spree = Spree::AppDependencies.new
        Spree::Dependencies = app.config.spree.dependencies
      end

      # filter sensitive information during logging
      initializer 'spree.params.filter', before: :load_config_initializers do |app|
        app.config.filter_parameters += [
          %r{^password$},
          %r{^password_confirmation$},
          CREDIT_CARD_NUMBER_PARAM,
          CREDIT_CARD_VERIFICATION_VALUE_PARAM,
        ]
      end

      initializer 'spree.core.checking_migrations', before: :load_config_initializers do |_app|
        Migrations.new(config, engine_name).check
      end

      # Load in mailer previews for apps to use in development.
      # We need to make sure we call `Preview.all` before requiring our
      # previews, otherwise any previews the app attempts to add need to be
      # manually required.
      if Rails.env.development?
        initializer "spree.mailer_previews" do
          ActionMailer::Preview.all
          Dir[root.join("lib/spree/mailer_previews/**/*_preview.rb")].each do |file|
            require_dependency file
          end
        end
      end
    end
  end
end

require 'spree/core/components'