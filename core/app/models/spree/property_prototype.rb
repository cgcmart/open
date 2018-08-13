# frozen_string_literal: true

module Spree
  class PropertyPrototype < Spree::Base
    belongs_to :prototype
    belongs_to :property

    validates :prototype, :property, presence: true
    validates :prototype_id, uniqueness: { scope: :property_id }
  end
end
