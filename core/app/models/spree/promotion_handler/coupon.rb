# frozen_string_literal: true

module Spree
  module PromotionHandler
    class Coupon
      attr_reader :order, :coupon_code
      attr_accessor :error, :success, :status_code

      def initialize(order)
        @order = order
        @coupon_code = order.coupon_code && order.coupon_code.downcase
      end

      def apply
        if order.coupon_code.present?
          if promotion.present? && promotion.actions.exists?
            handle_present_promotion
          elsif Promotion.with_coupon_code(order.coupon_code).try(:expired?)
            set_error_code :coupon_code_expired
          else
            set_error_code :coupon_code_not_found
          end
        else
          set_error_code :coupon_code_not_found
        end
        self
      end

      def remove(coupon_code)
        promotion = order.promotions.with_coupon_code(coupon_code)

        if promotion.present?
          # Order promotion has to be destroyed before line item removing
          order.order_promotions.find_by!(promotion_id: promotion.id).destroy

          remove_promotion_adjustments(promotion)
          order.update_with_updater!

          set_success_code :adjustments_deleted
        else
          set_error_code :coupon_code_not_found
        end
        self
      end

      def set_success_code(status_code)
        @status_code = status_code
        @success = I18n.t(status_code, scope: 'spree')
      end

      def set_error_code(status_code)
        @status_code = status_code
        @error = I18n.t(status_code, scope: 'spree')
      end

      def promotion
        @promotion ||= begin
          if promotion_code && promotion_code.promotion.active?
            promotion_code.promotion
          end
        end
      end

      def successful?
        success.present? && error.blank?
      end

      private

      def promotion_code
        @promotion_code ||= Spree::PromotionCode.where(value: coupon_code).first
      end

      def remove_promotion_adjustments(promotion)
        promotion_actions_ids = promotion.actions.pluck(:id)
        order.all_adjustments.where(source_id: promotion_actions_ids,
                                    source_type: 'Spree::PromotionAction').destroy_all
      end

      def handle_present_promotion(promotion)
        return promotion_usage_limit_exceeded if promotion.usage_limit_exceeded? || promotion_code.usage_limit_exceeded?
        return promotion_applied if promotion_exists_on_order?(order, promotion)

        unless promotion.eligible?(order, promotion_code: promotion_code)
          self.error = promotion.eligibility_errors.full_messages.first unless promotion.eligibility_errors.blank?
          return (error || ineligible_for_this_order)
        end

        # If any of the actions for the promotion return `true`,
        # then result here will also be `true`.
        result = promotion.activate(order: order, promotion_code: promotion_code)
        if result
          order.recalculate
          set_success_code :coupon_code_applied
        else
          set_error_code :coupon_code_unknown_error
        end
      end

      def promotion_usage_limit_exceeded
        set_error_code :coupon_code_max_usage
      end

      def ineligible_for_this_order
        set_error_code :coupon_code_not_eligible
      end

      def promotion_applied
        set_error_code :coupon_code_already_applied
      end

      def promotion_exists_on_order?(order, promotion)
        order.promotions.include? promotion
      end
    end
  end
end