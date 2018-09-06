# frozen_string_literal: true

module Spree
  class ReturnItem < Spree::Base
    module ExchangeVariantEligibility
      class SameProduct
        def self.eligible_variants(variant)
          Spree::Variant.where(product_id: variant.product_id, is_master: variant.is_master?).in_stock_or_backorderable
        end
      end
    end
  end
end
