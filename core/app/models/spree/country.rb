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
      default = find_by(id: country_id) if country_id.present?
      default || find_by(iso: 'US') || first
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      name
    end

    private

    def ensure_not_default
      if id.eql?(Spree::Config[:default_country_id])
        errors.add(:base, I18n.t('spree.default_country_cannot_be_deleted'))
        throw(:abort)
      end
    end
  end
end
