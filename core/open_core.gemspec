# encoding: UTF-8

require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'open_core'
  s.version     = Spree.open_version
  s.summary     = 'Essential models, mailers, and classes for the Open e-commerce platform.'
  s.description = s.summary

  s.author       = 'Open Team'
  s.email        = 'open@china-guide.com'
  s.homepage     = 'http://china-guide.com'
  s.license      = 'BSD-3-Clause'

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'

  s.required_ruby_version     = '>= 2.3.0'
  s.required_rubygems_version = '>= 1.8.23'

  %w[
    actionmailer actionpack actionview activejob activemodel activerecord
    activesupport railties
  ].each do |rails_dep|
    s.add_dependency rails_dep, ['>= 5.1', '< 5.3.x']
  end

  s.add_dependency 'activemerchant', '~> 1.67'
  s.add_dependency 'acts_as_list', '~> 0.8'
  s.add_dependency 'acts-as-taggable-on', '~> 6.0'
  s.add_dependency 'awesome_nested_set', '~> 3.1.4'
  s.add_dependency 'cancancan', '~> 2.2'
  s.add_dependency 'carmen', '~> 1.1.0'
  s.add_dependency 'discard', '~> 1.0'
  s.add_dependency 'friendly_id', '~> 5.2.1'
  s.add_dependency 'kaminari-activerecord', '~> 1.1'
  s.add_dependency 'mini_magick', '~> 4.8.0'
  s.add_dependency 'money', '~> 6.13'
  s.add_dependency 'monetize', '~> 1.9.0'
  s.add_dependency 'paranoia', '~> 2.4'
  s.add_dependency 'ransack', '~> 2.1.1'
  s.add_dependency 'state_machines-activerecord', '~> 0.5'
end