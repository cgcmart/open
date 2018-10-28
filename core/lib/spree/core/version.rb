# frozen_string_literal: true

module Spree
  def self.open_version
    "2.5.0"
  end

  def self.open_gem_version
    Gem::Version.new(open_version)
  end
end
