# frozen_string_literal: true

module Spree
  class PrototypeTaxon < Spree::Base
    belongs_to :prototype
    belongs_to :taxon

    validates :prototype, :taxon, presence: true
    validates :prototype_id, uniqueness: { scope: :taxon_id }
  end
end
