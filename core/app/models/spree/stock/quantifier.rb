# frozen_string_literal: true

module Spree
  module Stock
    class Quantifier
      attr_reader :variant, :stock_location

      def initialize(variant, stock_location = nil)
        @variant        = variant
        @stock_items = Spree::StockItem.where(variant_id: variant)
        if stock_location
          @stock_items.where!(stock_location: stock_location)
        else
          @stock_items.joins!(:stock_location).merge!(Spree::StockLocation.active)
        end
      end

      def total_on_hand
        if variant.should_track_inventory?
          stock_items.sum(:count_on_hand)
        else
          Float::INFINITY
        end
      end

      def backorderable?
        stock_items.any?(&:backorderable)
      end

      def can_supply?(required)
        total_on_hand >= required || backorderable?
      end
    end
  end
end
