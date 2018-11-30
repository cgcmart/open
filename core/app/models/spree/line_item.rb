# frozen_string_literal: true

module Spree
  # Variants placed in the Order at a particular price.
  #
  # `Spree::LineItem` is an ActiveRecord model which records which `Spree::Variant`
  # a customer has chosen to place in their order. It also acts as the permenent
  # record of the customer's order by recording relevant price, taxation, and inventory
  # concerns. Line items can also have adjustments placed on them as part of the
  # promotion system.
  #
  class LineItem < Spree::Base
    class CurrencyMismatch < StandardError; end

    with_options inverse_of: :line_items do
      belongs_to :order, class_name: 'Spree::Order', touch: true
      belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant'
    end
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'

    has_one :product, through: :variant

    has_many :adjustments, as: :adjustable, inverse_of: :adjustable, dependent: :destroy
    has_many :inventory_units, inverse_of: :line_item

    has_many :line_item_actions, dependent: :destroy
    has_many :actions, through: :line_item_actions

    before_validation :normalize_quantity
    before_validation :set_required_attributes

    validates :variant, :order, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than: -1 }
    validates :price, numericality: true

    after_save :update_inventory

    before_destroy :update_inventory
    before_destroy :destroy_inventory_units

    delegate :name, :description, :sku, :should_track_inventory?, :options_text, :slug, to: :variant
    delegate :currency, to: :order, allow_nil: true

    attr_accessor :target_shipment

    self.whitelisted_ransackable_associations = ['variant']
    self.whitelisted_ransackable_attributes = ['variant_id']

    def amount
      price * quantity
    end
    alias subtotal amount

    def total
      amount + adjustment_total
    end
    alias final_amount total

    def total_before_tax
      amount + adjustments.select { |a| !a.tax? && a.eligible? }.sum(&:amount)
    end

    extend DisplayMoney
    money_methods :amount, :discounted_amount, :price,
                  :total, :adjustment_total, :additional_tax_total, :promo_total, :included_tax_total

    alias money_price display_price
    alias single_money display_price
    alias single_display_amount display_price

    alias money display_amount

    def money_price=(money)
      if !money
        self.price = nil
      elsif money.currency.iso_code != currency
        raise CurrencyMismatch, "Line item price currency must match order currency!"
      else
        self.price = money.to_d
      end
    end

    def sufficient_stock?
      Stock::Quantifier.new(variant).can_supply? quantity
    end

    def insufficient_stock?
      !sufficient_stock?
    end

    def options=(options = {})
      return unless options.present?

      assign_attributes options

      # When price is part of the options we are not going to fetch
      # it from the variant. Please note that this always allows to set
      # a price for this line item, even if there is no existing price
      # for the associated line item in the order currency.
      unless options.key?(:price) || options.key?('price')
        self.money_price = variant.price_for(pricing_options)
      end
    end

    def pricing_options
      Spree::Config.pricing_options_class.from_line_item(self)
    end

    def currency=(_currency)
    end

    private

    def normalize_quantity
      self.quantity = 0 if quantity.nil? || quantity < 0
    end

    def set_required_attributes
      return unless variant
      self.tax_category ||= variant.tax_category
      set_pricing_attributes
    end

    def set_pricing_attributes
      # If the legacy method #copy_price has been overridden, handle that gracefully
      return handle_copy_price_override if respond_to?(:copy_price)

      self.cost_price ||= variant.cost_price
      self.money_price = variant.price_for(pricing_options) if price.nil?
      true
    end

    def handle_copy_price_override
      copy_price
    end

    def copy_price
      if variant
        update_price if price.nil?
        self.cost_price = variant.cost_price if cost_price.nil?
        self.currency = variant.currency if currency.nil?
      end
    end

    def update_inventory
      if (saved_changes? || target_shipment.present?) && order.has_checkout_step?('delivery')
        Spree::OrderInventory.new(order, self).verify(target_shipment)
      end
    end

    def destroy_inventory_units
      inventory_units.destroy_all
    end

    def update_adjustments
      if saved_change_to_quantity?
        recalculate_adjustments
        update_tax_charge # Called to ensure pre_tax_amount is updated.
      end
    end

    def recalculate_adjustments
      Adjustable::AdjustmentsUpdater.update(self)
    end

    def update_tax_charge
      Spree::TaxRate.adjust(order, [self])
    end

    def ensure_proper_currency
      unless currency == order.currency
        errors.add(:currency, :must_match_order_currency)
      end
    end
  end
end
