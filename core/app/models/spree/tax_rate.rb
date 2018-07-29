# frozen_string_literal: true

require 'discard'

module Spree
  class TaxRate < Spree::Base
    acts_as_paranoid

        include Discard::Model
    self.discard_column = :deleted_at

    # Need to deal with adjustments before calculator is destroyed.
    before_destroy :remove_adjustments_from_incomplete_orders
    before_discard :remove_adjustments_from_incomplete_orders

    include Spree::CalculatedAdjustments
    include Spree::AdjustmentSource

    belongs_to :zone, class_name: "Spree::Zone", inverse_of: :tax_rates

    has_many :tax_rate_tax_categories,
      class_name: 'Spree::TaxRateTaxCategory',
      dependent: :destroy,
      inverse_of: :tax_rate
    has_many :tax_categories,
      through: :tax_rate_tax_categories,
      class_name: 'Spree::TaxCategory',
      inverse_of: :tax_rates

    has_many :adjustments, as: :source
    has_many :shipping_rate_taxes, class_name: "Spree::ShippingRateTax"

    validates :amount, presence: true, numericality: true

    scope :for_address, ->(address) { joins(:zone).merge(Spree::Zone.for_address(address)) }
    scope :for_country, ->(country) { for_address(Spree::Tax::TaxLocation.new(country: country)) }

    scope :for_zone, ->(zone) do
      if zone
        where(zone_id: Spree::Zone.with_shared_members(zone).pluck(:id))
      else
        none
      end
    end
    scope :included_in_price, -> { where(included_in_price: true) }

    # Creates necessary tax adjustments for the order.
    def adjust(_order_tax_zone, item)
      amount = compute_amount(item)

      item.adjustments.create!(
        source: self,
        amount: amount,
        order_id: item.order_id,
        label: adjustment_label(amount),
        included: included_in_price
      )
    end

    # This method is used by Adjustment#update to recalculate the cost.
    def compute_amount(item)
      calculator.compute(item)
    end

    def active?
      (starts_at.nil? || starts_at < Time.current) &&
        (expires_at.nil? || expires_at > Time.current)
    end

    def adjustment_label(amount)
      I18n.t(
        translation_key(amount),
        scope: "spree.adjustment_labels.tax_rates",
        name: name.presence || tax_categories.map(&:name).join(", "),
        amount: amount_for_adjustment_label
      )
    end

    def tax_category=(category)
      self.tax_categories = [category]
    end

    def tax_category
      tax_categories[0]
    end

    private

    def amount_for_adjustment_label
      ActiveSupport::NumberHelper::NumberToPercentageConverter.convert(
        amount * 100,
        locale: I18n.locale
      )
    end

    def translation_key(_amount)
      key = included_in_price? ? "vat" : "sales_tax"
      key += "_with_rate" if show_rate_in_label?
      key.to_sym
    end
  end
end
