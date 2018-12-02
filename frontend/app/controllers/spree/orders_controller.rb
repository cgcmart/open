# frozen_string_literal: true

module Spree
  class OrdersController < Spree::StoreController
    helper 'spree/products', 'spree/orders'

    respond_to :html

    before_action :store_token
    before_action :assign_order_with_lock, only: :update
    around_action :lock_order, only: :update
    before_action :apply_coupon_code, only: :update
    skip_before_action :verify_authenticity_token, only: [:populate]

    def show
      @order = Spree::Order.find_by!(number: params[:id])
      authorize! :read, @order, cookies.signed[:token]
    end

    def update
      authorize! :update, @order, cookies.signed[:token]
      if Cart::Update.call(order: @order, params: order_params).success?
        respond_with(@order) do |format|
          format.html do
            if params.key?(:checkout)
              @order.next if @order.cart?
              redirect_to checkout_state_path(@order.checkout_steps.first)
            else
              redirect_to cart_path
            end
          end
        end
      else
        respond_with(@order)
      end
    end

    # Shows the current incomplete order from the session
    def edit
      @order = current_order || Order.incomplete.find_or_initialize_by(token: cookies.signed[:token])
      authorize! :read, @order, cookies.signed[:token]
      associate_user
    end

    def empty
      current_order.try(:empty!)

      redirect_to spree.cart_path
    end

    def accurate_title
      if @order&.completed?
        t('spree.order_number', number: @order.number)
      else
        t('spree.shopping_cart')
      end
    end

    private

    def check_authorization
      order = Spree::Order.find_by(number: params[:id]) if params[:id].present?
      order ||= current_order

      if order && action_name.to_sym == :show
        authorize! :show, order, cookies.signed[:token]
      elsif order
        authorize! :edit, order, cookies.signed[:token]
      else
        authorize! :create, Spree::Order
      end
    end

    def order_params
      if params[:order]
        params[:order].permit(*permitted_order_attributes)
      else
        {}
      end
    end

    def assign_order
      @order = current_order
      unless @order
        flash[:error] = t('spree.order_not_found')
        redirect_to root_path and return
      end
    end
  end
end
