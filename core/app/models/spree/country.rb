# frozen_string_literal: true

module Spree
  class Country < Spree::Base
    # we need to have this callback before any dependent: :destroy associations
    # https://github.com/rails/rails/issues/3458
    before_destroy :ensure_not_default

    has_many :states, -> { order(:name) }, dependent: :destroy
    has_many :addresses, dependent: :nullify
    has_many :prices, class_name: "Spree::Price", foreign_key: "country_iso", primary_key: "iso"

    validates :name, :iso_name, presence: true

    def self.default
      find_by!(iso: Spree::Config.default_country_iso)
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      name
    end
  end
end
