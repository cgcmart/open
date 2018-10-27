# frozen_string_literal: true

require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'open_backend'
  s.version     = Spree.open_version
  s.summary     = 'Admin interface for the Open e-commerce framework.'
  s.description = s.summary

  s.required_ruby_version = '>= 2.3.0'

  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.org'
  s.license = 'BSD-3-Clause'

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'open_api', s.version
  s.add_dependency 'open_core', s.version

  s.add_dependency 'font-awesome-rails', '~> 4.0'
  s.add_dependency 'jbuilder'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'kaminari'
  s.add_dependency 'sassc-rails'

  s.add_dependency 'autoprefixer-rails'
  s.add_dependency 'handlebars_assets', '~> 0.23'
end
