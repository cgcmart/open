# frozen_string_literal: true

require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.authors       = ["Ryan Bigg"]
  s.email         = ["ryan@spreecommerce.com"]
  s.description   = %q{Spree's API}
  s.summary       = %q{Spree's API}
  s.homepage      = 'http://spreecommerce.org'
  s.license       = 'BSD-3-Clause'

  s.required_ruby_version = '>= 2.3.0'

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.name          = "spree_api"
  s.require_paths = ["lib"]
  s.version       = Spree.version

  s.add_development_dependency 'jsonapi-rspec'

  s.add_dependency 'spree_core', s.version
  s.add_dependency 'jbuilder'
  s.add_dependency 'kaminari-activerecord', '~> 1.1'
  s.add_dependency 'fast_jsonapi', '~> 1.3.0'
  s.add_dependency 'doorkeeper'
end
