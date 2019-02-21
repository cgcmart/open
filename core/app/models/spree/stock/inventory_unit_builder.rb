# frozen_string_literal: true

module Spree
  module Stock
    class InventoryUnitBuilder
      def initialize(order)
        @order = order
      end

      def units
        @order.line_items.flat_map do |line_item|
          Array.new(line_item.quantity) do
            Spree::InventoryUnit.new(
              pending: true,
              line_item_id: line_item.id,
              variant_id: line_item.variant_id,
              quantity: line_item.quantity
            )
          end
        end
      end
    end
  end
end