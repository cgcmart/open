# frozen_string_literal: true

module Spree
  class OrderContents
    attr_accessor :order

    def initialize(order)
      @order = order
    end

    def add(variant, quantity = 1, options = {})
      Spree::Cart::AddItem.call(order: order, variant: variant, quantity: quantity, options: options).value
    end

    def remove(variant, quantity = 1, options = {})
      Spree::Cart::RemoveItem.call(order: order, variant: variant, quantity: quantity, options: options).value
    end

    def remove_line_item(line_item, options = {})
      Spree::Cart::RemoveLineItem.call(order: @order, line_item: line_item, options: options).value
    end

    def update_cart(params)
      Spree::Cart::Update.call(order: order, params: params).value
    end

    def advance
      while @order.next; end
    end

    def approve(user: nil, name: nil)
      if user.blank? && name.blank?
        raise ArgumentError, 'user or name must be specified'
      end

      order.update_attributes!(
        approver: user,
        approver_name: name,
        approved_at: Time.current
      )
    end
  end
end
