# frozen_string_literal: true

module Spree
  # An order's planned shipments including tracking and cost.
  #
  class Shipment < Spree::Base
    belongs_to :order, class_name: 'Spree::Order', touch: true, inverse_of: :shipments
    belongs_to :stock_location, class_name: 'Spree::StockLocation'

    has_many :adjustments, as: :adjustable, inverse_of: :adjustable, dependent: :delete_all
    has_many :inventory_units, dependent: :destroy, inverse_of: :shipment
    has_many :shipping_rates, -> { order(:cost) }, dependent: :destroy, inverse_of: :shipment
    has_many :shipping_methods, through: :shipping_rates
    has_many :state_changes, as: :stateful
    
    before_validation :set_cost_zero_when_nil

    before_destroy :ensure_can_destroy

    attr_accessor :special_instructions, :suppress_mailer

    accepts_nested_attributes_for :inventory_units

    make_permalink field: :number, length: 11, prefix: 'H'

    scope :pending, -> { with_state('pending') }
    scope :ready,   -> { with_state('ready') }
    scope :shipped, -> { with_state('shipped') }
    scope :trackable, -> { where("tracking IS NOT NULL AND tracking != ''") }
    scope :with_state, ->(*s) { where(state: s) }
    # sort by most recent shipped_at, falling back to created_at. add "id desc" to make specs that involve this scope more deterministic.
    scope :reverse_chronological, -> { order(Arel.sql('coalesce(spree_shipments.shipped_at, spree_shipments.created_at) desc'), id: :desc) }
    scope :by_store, ->(store) { joins(:order).merge(Spree::Order.by_store(store)) }

    # shipment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :pending, use_transactions: false do
      event :ready do
        transition from: :pending, to: :shipped, if: :can_transition_from_pending_to_shipped?
        transition from: :pending, to: :ready, if: :can_transition_from_pending_to_ready?
      end

      event :pend do
        transition from: :ready, to: :pending
      end

      event :ship do
        transition from: [:ready, :canceled], to: :shipped
      end
      after_transition to: :shipped, do: :after_ship

      event :cancel do
        transition to: :canceled, from: [:pending, :ready]
      end
      after_transition to: :canceled, do: :after_cancel

      event :resume do
        transition from: :canceled, to: :ready, if: :can_transition_from_canceled_to_ready?
        transition from: :canceled, to: :pending
      end
      after_transition from: :canceled, to: [:pending, :ready, :shipped], do: :after_resume

      after_transition do |shipment, transition|
        shipment.state_changes.create!(
          previous_state: transition.from,
          next_state:     transition.to,
          name:           'shipment'
        )
      end
    end

    self.whitelisted_ransackable_associations = ['order']
    self.whitelisted_ransackable_attributes = ['number']

    delegate :tax_category, :tax_category_id, to: :selected_shipping_rate, allow_nil: true

    def can_transition_from_pending_to_shipped?
      !requires_shipment?
    end

    def can_transition_from_pending_to_ready?
      order.can_ship? &&
        inventory_units.all? { |iu| iu.shipped? || iu.allow_ship? || iu.canceled? } &&
        (order.paid? || !Spree::Config[:require_payment_to_ship])
    end

    def can_transition_from_canceled_to_ready?
      can_transition_from_pending_to_ready?
    end

    extend DisplayMoney
    money_methods(
      :cost, :amount, :item_cost,
      :total, :total_before_tax 
      )
    alias_attribute :amount, :cost

    def after_cancel
      manifest.each { |item| manifest_restock(item) }
    end

    def after_resume
      manifest.each { |item| manifest_unstock(item) }
    end

    def backordered?
      inventory_units.any?(&:backordered?)
    end

    # TODO: delegate currency to Order, order.currency is mandatory
    def currency
      order ? order.currency : Spree::Config[:currency]
    end

    def total
      cost + adjustment_total
    end

    # @return [BigDecimal] the amount of this item, taking into consideration
    #   all non-tax adjustments.
    def total_before_tax
      amount + adjustments.select { |a| !a.tax? && a.eligible? }.sum(&:amount)
    end

    # @return [BigDecimal] the amount of this shipment before VAT tax
    # @note just like `cost`, this does not include any additional tax
    def total_excluding_vat
      total_before_tax - included_tax_total
    end

    def total_with_items
      total + item_cost
    end

    def editable_by?(_user)
      !shipped?
    end

    def free?
      return true if total == BigDecimal(0)

      adjustments.promotion.any? { |p| p.source.type == 'Spree::Promotion::Actions::FreeShipping' }
    end

    # Decrement the stock counts for all pending inventory units in this
    # shipment and mark.
    # Any previous non-pending inventory units are skipped as their stock had
    # already been allocated.
    def finalize!
      finalize_pending_inventory_units
    end

    def include?(variant)
      inventory_units_for(variant).present?
    end

    def inventory_units_for(variant)
      inventory_units.where(variant_id: variant.id)
    end

    def inventory_units_for_item(line_item, variant = nil)
      inventory_units.where(line_item_id: line_item.id, variant_id: line_item.variant_id || variant.id)
    end

    def item_cost
      line_items.map(&:total).sum
    end

    def line_items
      inventory_units.includes(:line_item).map(&:line_item).uniq
    end

    def ready_or_pending?
      ready? || pending?
    end

    def refresh_rates
      return shipping_rates if shipped?
      return [] unless can_get_rates?

      # StockEstimator.new assigment below will replace the current shipping_method
      original_shipping_method_id = shipping_method.try(:id)

      new_rates = Spree::Config.stock.estimator_class.new.shipping_rates(to_package)

      # If one of the new rates matches the previously selected shipping
      # method, select that instead of the default provided by the estimator.
      # Otherwise, keep the default.
      selected_rate = new_rates.detect{ |rate| rate.shipping_method_id == original_shipping_method_id }
      if selected_rate
        new_rates.each do |rate|
          rate.selected = (rate == selected_rate)
        end
      end

      self.shipping_rates = new_rates
      save!

      shipping_rates
    end

    def select_shipping_method(shipping_method)
      estimator = Spree::Config.stock.estimator_class.new
      rates = estimator.shipping_rates(to_package, false)
      rate = rates.detect { |r| r.shipping_method_id == shipping_method.id }
      rate.selected = true
      self.shipping_rates = [rate]
    end

    def selected_shipping_rate
      shipping_rates.detect(&:selected?)
    end

    def manifest
      @manifest ||= Spree::ShippingManifest.new(inventory_units: inventory_units).items
    end

    def selected_shipping_rate_id
      selected_shipping_rate.try(:id)
    end

    def selected_shipping_rate_id=(id)
      return if selected_shipping_rate_id == id
      new_rate = shipping_rates.detect { |rate| rate.id == id.to_i }
      unless new_rate
        fail(
          ArgumentError,
          "Could not find shipping rate id #{id} for shipment #{number}"
        )
      end

      transaction do
        selected_shipping_rate.update!(selected: false) if selected_shipping_rate
        new_rate.update!(selected: true)
      end
    end

    def determine_state(order)
      return 'canceled' if order.canceled?
      return 'shipped' if shipped?
      return 'pending' unless order.can_ship?
      if can_transition_from_pending_to_ready?
        'ready'
      else
        'pending'
      end
    end

    def set_up_inventory(state, variant, _order, line_item)
      inventory_units.create(
        state: state,
        variant_id: variant.id,
        line_item_id: line_item.id
      )
    end

    def shipped=(value)
      return unless value == '1' && shipped_at.nil?
      self.shipped_at = Time.current
    end

    def shipping_method
      selected_shipping_rate&.shipping_method || shipping_rates.first&.shipping_method
    end

    # Only one of either included_tax_total or additional_tax_total is set
    # This method returns the total of the two. Saves having to check if
    # tax is included or additional.
    def tax_total
      included_tax_total + additional_tax_total
    end

    def to_package
      package = Stock::Package.new(stock_location)
      package.shipment = self
      inventory_units.includes(:variant).joins(:variant).group_by(&:state).each do |state, state_inventory_units|
        package.add_multiple state_inventory_units, state.to_sym
      end
      package
    end

    def to_param
      number
    end

    def tracking_url
      return nil unless tracking && shipping_method

      @tracking_url ||= shipping_method&.build_tracking_url(tracking)
    end

    def update_amounts
      if selected_shipping_rate
        self.cost = selected_shipping_rate.cost
        if changed?
          update_columns(
            cost: cost,
            updated_at: Time.current
          )
        end
      end
    end

    # Update Shipment and make sure Order states follow the shipment changes
    def update_attributes_and_order(params = {})
      if update_attributes params
        if params.key? :selected_shipping_rate_id
          # Changing the selected Shipping Rate won't update the cost (for now)
          # so we persist the Shipment#cost before calculating order shipment
          # total and updating payment state (given a change in shipment cost
          # might change the Order#payment_state)
          update_amounts
          order.recalculate
        end

        true
      end
    end

    # Updates various aspects of the Shipment while bypassing any callbacks.  Note that this method takes an explicit reference to the
    # Order object.  This is necessary because the association actually has a stale (and unsaved) copy of the Order and so it will not
    # yield the correct results.
    def update_state
      old_state = state
      new_state = determine_state(order)
      if new_state != old_state
        update_columns(
          state: new_state,
          updated_at: Time.current
        )
        after_ship if new_state == 'shipped'
      end
    end

    def transfer_to_shipment(variant, quantity, shipment_to_transfer_to)
      Spree::FulfilmentChanger.new(
        current_shipment:       self,
        desired_shipment:       shipment_to_transfer_to,
        variant:                variant,
        quantity:               quantity
      ).run!
    end

    def requires_shipment?
      !stock_location || stock_location.fulfillable?
    end

    def ship_address
      order.ship_address if order
    end

    private

    def after_ship
      order.shipping.ship_shipment(self, suppress_mailer: suppress_mailer)
    end

    def can_get_rates?
      order.ship_address&.valid?
    end

    def manifest_restock(item)
      if item.states['on_hand'].to_i > 0
        stock_location.restock item.variant, item.states['on_hand'], self
      end

      if item.states['backordered'].to_i > 0
        stock_location.restock_backordered item.variant, item.states['backordered']
      end
    end

    def manifest_unstock(item)
      stock_location.unstock item.variant, item.quantity, self
    end

    def set_cost_zero_when_nil
      self.cost = 0 unless cost
    end

    def ensure_can_destroy
      if shipped? || canceled?
        errors.add(:state, :cannot_destroy, state: state)
        throw :abort
      end
    end
  end
end