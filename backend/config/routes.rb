# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :admin do
    put '/locale/set', to: 'locale#set', defaults: { format: :json }, as: :set_locale

    resources :promotions do
      resources :promotion_rules
      resources :promotion_actions
      resources :promotion_codes, only: [:index]
      member do
        post :clone
      end
    end

    resources :promotion_categories, except: [:show]

    resources :zones

    resources :tax_categories

    resources :products do
      resources :product_properties do
        collection do
          post :update_positions
        end
      end
      resources :variant_property_rule_values, only: [:destroy] do
        collection do
          post :update_positions
        end
      end
      resources :images do
        collection do
          post :update_positions
        end
      end
      member do
        post :clone
      end
      resources :variants, only: [:index, :edit, :update, :new, :create, :destroy] do
        collection do
          post :update_positions
        end
      end
      resources :variants_including_master, only: [:update]
      resources :prices, only: [:destroy, :index, :edit, :update, :new, :create]
    end
    get '/products/:product_slug/stock', to: 'stock_items#index', as: :product_stock

    resources :option_types do
      collection do
        post :update_positions
        post :update_values_positions
      end
    end

    delete '/option_values/:id', to: 'option_values#destroy', as: :option_value

    resources :properties do
      collection do
        get :filtered
      end
    end

    delete '/product_properties/:id', to: 'product_properties#destroy', as: :product_property

    resources :prototypes do
      member do
        get :select
      end

      collection do
        get :available
      end
    end

    resources :orders, except: [:show] do
      member do
        get :cart
        put :advance
        get :confirm
        put :complete
        post :resend
        get '/adjustments/unfinalize', to: 'orders#unfinalize_adjustments'
        get '/adjustments/finalize', to: 'orders#finalize_adjustments'
        put :approve
        put :cancel
        put :resume
        get :store
        put :set_store
      end

      resource :customer, controller: 'orders/customer_details'
      resources :customer_returns, only: [:index, :new, :edit, :create, :update] do
        member do
          put :refund
        end
      end

      resources :adjustments
      resources :return_authorizations do
        member do
          put :fire
        end
      end
      resources :payments do
        member do
          put :fire
        end

        resources :log_entries
        resources :refunds, only: [:new, :create, :edit, :update]
      end

      resources :reimbursements, only: [:index, :create, :show, :edit, :update] do
        member do
          post :perform
        end
      end

      resources :cancellations, only: [:index] do
        collection do
          post :short_ship
        end
      end
    end

    resource :general_settings, only: :edit
    resources :stores, only: [:index, :new, :create, :edit, :update]

    resources :return_items, only: [:update]

    resources :taxonomies do
      collection do
        post :update_positions
      end
      resources :taxons
    end

    resources :taxons, only: [:index, :show]

    resources :reports, only: [:index] do
      collection do
        get :sales_total
        post :sales_total
      end
    end

    resources :reimbursement_types, only: [:index]
    resources :adjustment_reasons, except: [:show, :destroy]
    resources :refund_reasons, except: [:show, :destroy]
    resources :return_reasons, except: [:show, :destroy]

    resources :shipping_methods
    resources :shipping_categories

    resources :stock_locations do
      resources :stock_movements, except: [:edit, :update, :destroy]
      collection do
        post :transfer_stock
        post :update_positions
      end
    end

    resources :stock_items, only: [:create, :update, :destroy]
    resources :store_credit_categories
    resources :tax_rates
    resources :payment_methods do
      collection do
        post :update_positions
      end
    end
    resources :roles

    resources :users do
      member do
        get :addresses
        put :addresses
        put :clear_api_key
        put :generate_api_key
        get :items
        get :orders
      end
      resources :store_credits, except: [:destroy] do
        member do
          get :edit_amount
          put :update_amount
          get :edit_validity
          put :invalidate
        end
      end
    end

    resources :style_guide, only: [:index]
  end

  get '/admin', to: 'admin/orders#index', as: :admin
end
