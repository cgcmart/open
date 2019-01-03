# frozen_string_literal: true

module Spree
  class PromotionRuleStore < Spree::Base
    belongs_to :promotion_rule, class_name: "Spree::PromotionRule"
    belongs_to :store, class_name: "Spree::Store"
  end
end
