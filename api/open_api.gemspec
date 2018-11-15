# frozen_string_literal: true

require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.com'
  s.license      = 'BSD-3-Clause'

  s.summary       = 'REST API for the Open e-commerce framework.'
  s.description   = s.summary

  s.required_ruby_version = '>= 2.3.0'

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.name          = "open_api"
  s.require_paths = ["lib"]
  s.version       = Spree.open_version

  s.add_development_dependency 'jsonapi-rspec'

  s.add_dependency 'open_core', s.version
  s.add_dependency 'jbuilder'
  s.add_dependency 'kaminari-activerecord', '~> 1.1'
  s.add_dependency 'fast_jsonapi', '~> 1.3.0'
  s.add_dependency 'doorkeeper', '~> 5.0'
  s.add_dependency 'responders'
end
