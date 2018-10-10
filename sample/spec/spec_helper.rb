# frozen_string_literal: true

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV['RAILS_ENV'] ||= 'test'

require 'spree_sample'
require 'spree/testing_support/dummy_app'
DummyApp.setup(
  gem_root: File.expand_path('..', __dir__),
  lib_name: 'spree_sample'
)

require 'rspec/rails'

RSpec.configure do |config|
  config.color = true
  config.infer_spec_type_from_file_location!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.filter_run_including :active_storage
  config.run_all_when_everything_filtered = true

  config.include FactoryBot::Syntax::Methods

  config.order = :random
  Kernel.srand config.seed
end
