# encoding: UTF-8
require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'open_sample'
  s.version     = Spree.open_version
  s.summary     = 'Sample data (including images) for use with Open.'
  s.description = s.summary

  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.com'
  s.license = 'BSD-3-Clause'

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency 'open_core', s.version
end
