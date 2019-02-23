# encoding: UTF-8
require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'open_frontend'
  s.version     = Spree.open_version
  s.summary     = 'Cart and storeFront for the Open e-commerce project.'
  s.description = s.summary

  s.required_ruby_version = '>= 2.5.0'

  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.com'

  s.license = 'BSD-3-Clause'
  s.files        = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'open_api', s.version
  s.add_dependency 'open_core', s.version

  s.add_dependency 'bootstrap', '>= 4.3.1'
  s.add_dependency 'glyphicons',      '~> 1.0.2'
  s.add_dependency 'canonical-rails', '~> 0.2.3'
  s.add_dependency 'jquery-rails'

  s.add_development_dependency 'capybara-accessible'
end