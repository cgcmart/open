# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Finders', 'app/finders'
    add_group 'Mailers', 'app/mailers'
    add_group 'Paginators', 'app/paginators'
    add_group 'Services', 'app/services'
    add_group 'Sorters', 'app/sorters'
    add_group 'Validators', 'app/validators'
    add_group 'Libraries', 'lib'

    add_filter '/bin/'
    add_filter '/db/'
    add_filter '/script/'
    add_filter '/spec/'

    coverage_dir "#{ENV['COVERAGE_DIR']}/core" if ENV['COVERAGE_DIR']
  end
end

require 'rspec/core'

require 'spree/testing_support/preferences'
require 'spree/config'
require 'with_model'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_including :active_storage
  config.run_all_when_everything_filtered = true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before :each do
    reset_spree_preferences
  end

  config.include Spree::TestingSupport::Preferences
  config.extend WithModel

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.order = :random
  Kernel.srand config.seed
end
