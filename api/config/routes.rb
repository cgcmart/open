# frozen_string_literal: true

spree_path = Rails.application.routes.url_helpers.try(:spree_path, trailing_slash: true) || '/'

Rails.application.routes.draw do
  use_doorkeeper scope: "#{spree_path}/spree_oauth"
end

Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :users do
      member do
        put :generate_api_key
        put :clear_api_key
      end
    end
  end

  namespace :api, defaults: { format: 'json' } do
    resources :promotions, only: [:show]

    resources :products do
      resources :images
      resources :variants
      resources :product_properties
    end

    concern :order_routes do
      resources :line_items
      resources :payments do
        member do
          put :authorize
          put :capture
          put :purchase
          put :void
          put :credit
        end
      end

      resources :addresses, only: [:show, :update]

      resources :return_authorizations do
        member do
          put :cancel
        end
      end
    end

    resources :checkouts, only: [:update], concerns: :order_routes do
      member do
        put :next
        put :advance
        put :complete
      end
    end

    resources :variants do
      resources :images
    end

    resources :option_types do
      resources :option_values
    end
    resources :option_values

    resources :option_values, only: :index

    get '/orders/mine', to: 'orders#mine', as: 'my_orders'
    get '/orders/current', to: 'orders#current', as: 'current_order'

    resources :orders, concerns: :order_routes do
      member do
        put :cancel
        put :empty
        put :apply_coupon_code
      end
    end

    resources :zones
    resources :countries, only: [:index, :show] do
      resources :states, only: [:index, :show]
    end

    resources :shipments, only: [:create, :update] do
      collection do
        post 'transfer_to_location'
        post 'transfer_to_shipment'
        get :mine
      end

      member do
        get :estimated_rates
        put :select_shipping_method
        put :ready
        put :ship
        put :add
        put :remove
      end
    end
    resources :states, only: [:index, :show]

    resources :taxonomies do
      member do
        get :jstree
      end
      resources :taxons do
        member do
          get :jstree
        end
      end
    end

    resources :taxons, only: [:index]

    resources :inventory_units, only: [:show, :update]

    resources :users do
      resources :credit_cards, only: [:index]
      resource :address_book, only: [:show, :update, :destroy]
    end

    resources :credit_cards, only: [:update]

    resources :properties
    resources :stock_locations do
      resources :stock_movements
      resources :stock_items
    end

    resources :stock_items, only: [:index, :update, :destroy]
    resources :stores

    resources :tags, only: :index

    resources :store_credit_events, only: [] do
      collection do
        get :mine
      end
    end

    get '/config/money', to: 'config#money'
    get '/config', to: 'config#show'
    put '/classifications', to: 'classifications#update', as: :classifications
    get '/taxons/products', to: 'taxons#products', as: :taxon_products
  end

  namespace :v2 do
    if Rails.env.development? || ENV['EXPOSE_SWAGGER']
      get 'storefront.yml', to: 'swagger#storefront', as: 'swagger_storefront', format: 'yml'
    end

    namespace :storefront do
      resource :cart, controller: :cart, only: %i[show create] do
          post   :add_item
          post   :empty
          delete 'remove_line_item/:line_item_id', to: 'cart#remove_line_item', as: :cart_remove_line_item
          patch  :set_quantity
          patch  :apply_coupon_code
        end

        resource :checkout, controller: :checkout, only: %i[update] do
          patch :next
          patch :advance
          patch :complete
        end

        resources :products, only: %i[index show]
        resources :taxons, only: %i[index show]
      end
    end

    get '/404', to: 'errors#render_404'
  end
end
