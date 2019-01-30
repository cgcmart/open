# frozen_string_literal: true

module Spree
  class Promotion < Spree::Base
    module Actions
      class CreateItemAdjustments < PromotionAction
        include Spree::CalculatedAdjustments
        include Spree::AdjustmentSource

        has_many :adjustments, as: :source

        delegate :eligible?, to: :promotion

        before_validation :ensure_action_has_calculator
        before_destroy :remove_adjustments_from_incomplete_orders
        before_discard :remove_adjustments_from_incomplete_orders

        def perform(payload = {})
          order = payload[:order]
          promotion = payload[:promotion]
          promotion_code = payload[:promotion_code]

          results = line_items_to_adjust(promotion, order).map do |line_item|
            create_adjustment(line_item, order, promotion_code)
          end

          results.any?
        end

        def compute_amount(adjustable)
          order = adjustable.is_a?(Order) ? adjustable : adjustable.order
          return 0 unless promotion.line_item_actionable?(order, adjustable)
          promotion_amount = calculator.compute(adjustable)
          if !promotion_amount.is_a?(BigDecimal)
            Spree::Deprecation.warn "#{calculator.class.name}#compute returned #{promotion_amount.inspect}, it should return a BigDecimal"
          end
          promotion_amount ||= BigDecimal(0)
          promotion_amount = promotion_amount.abs
          [adjustable.amount, promotion_amount].min * -1
        end

        # Removes any adjustments generated by this action from the order's
        #  line items.
        # @param order [Spree::Order] the order to remove the action from.
        # @return [void]
        def remove_from(order)
          order.line_items.each do |line_item|
            line_item.adjustments.each do |adjustment|
              if adjustment.source == self
                line_item.adjustments.destroy(adjustment)
              end
            end
          end
        end

        private

        def create_adjustment(adjustable, order, promotion_code)
          amount = compute_amount(adjustable)
          return if amount == 0
          adjustable.adjustments.create!(
            source: self,
            amount: amount,
            order: order,
            promotion_code: promotion_code,
            label: I18n.t('spree.adjustment_labels.line_item', promotion: Spree::Promotion.model_name.human, promotion_name: promotion.name)
          )
          true
        end

        # Tells us if there if the specified promotion is already associated with the line item
        # regardless of whether or not its currently eligible. Useful because generally
        # you would only want a promotion action to apply to line item no more than once.
        #
        # Receives an adjustment +source+ (here a PromotionAction object) and tells
        # if the order has adjustments from that already
        def promotion_credit_exists?(adjustable)
          adjustments.where(adjustable_id: adjustable.id).exists?
        end

        def ensure_action_has_calculator
          return if calculator
          self.calculator = Calculator::PercentOnLineItem.new
        end

        def line_items_to_adjust(promotion, order)
          excluded_ids = adjustments.
            where(adjustable_id: order.line_items.pluck(:id), adjustable_type: 'Spree::LineItem').
            pluck(:adjustable_id).
            to_set

          order.line_items.select do |line_item|
            !excluded_ids.include?(line_item.id) &&
              promotion.line_item_actionable?(order, line_item)
          end
        end
      end
    end
  end
end