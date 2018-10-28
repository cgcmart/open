# encoding: UTF-8

# frozen_string_literal: true

require_relative 'core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'open'
  s.version     = Spree.open_version
  s.summary     = 'Full-stack e-commerce framework for Ruby on Rails.'
  s.description = 'Spree is an open source e-commerce framework for Ruby on Rails.'

  s.required_ruby_version = '>= 2.3.0'

  s.files        = Dir['README.md', 'lib/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.com'
  s.license      = 'BSD-3-Clause'

  s.add_dependency 'open_api', s.version
  s.add_dependency 'open_backend', s.version
  s.add_dependency 'open_core', s.version
  s.add_dependency 'open_frontend', s.version
  s.add_dependency 'open_sample', s.version
end
