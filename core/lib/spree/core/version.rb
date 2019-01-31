# frozen_string_literal: true

module Spree
  def self.open_version
  VERSION = "2.5.0"

  def self.solidus_version
    VERSION
  end

  def self.open_gem_version
    Gem::Version.new(open_version)
  end
end