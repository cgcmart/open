# frozen_string_literal: true

module Spree
  class OptionTypePrototype < Spree::Base
    belongs_to :option_type
    belongs_to :prototype
    validates :prototype, :option_type, presence: true
    validates :prototype_id, uniqueness: { scope: :option_type_id }
  end
end
