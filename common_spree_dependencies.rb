# frozen_string_literal: true

# By placing all of Spree's shared dependencies in this file and then loading
# it for each component's Gemfile, we can be sure that we're only testing just
# the one component of Spree.
source 'https://rubygems.org'

gemspec require: false

rails_version = ENV['RAILS_VERSION'] || '~> 5.2.0'
gem 'rails', rails_version, require: false

gem 'sassc-rails'
gem 'sass', '~> 3.6.0' # https://github.com/sass/ruby-sass/issues/94
gem 'doorkeeper'

platforms :ruby do
  gem 'mysql2', require: false
  gem 'pg', '~> 1.0', require: false
  gem 'sqlite3', require: false
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
end

group :test do
  gem 'capybara', '~> 2.16'
  gem 'capybara-screenshot', '~> 1.0.22'
  gem 'database_cleaner', '~> 1.3'
  gem 'email_spec'
  gem 'factory_bot_rails', '~> 4.8'
  gem 'i18n-tasks', '~> 0.9', require: false
  gem 'launchy'
  gem 'rspec-activemodel-mocks', '~> 1.0'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 3.7.2'
  gem 'rspec_junit_formatter'
  gem 'jsonapi-rspec'
  gem 'simplecov'
  gem 'webmock', '~> 3.0.1'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
end

group :test, :development do
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'pry-byebug'
end
