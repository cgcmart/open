# frozen_string_literal: true

# This is the primary location for defining spree preferences
#
# The expectation is that this is created once and stored in
# the spree environment
#
# setters:
# a.color = :blue
# a[:color] = :blue
# a.set :color = :blue
# a.preferred_color = :blue
#
# getters:
# a.color
# a[:color]
# a.get :color
# a.preferred_color
#
require 'spree/core/search/base'

module Spree
  class AppConfiguration < Preferences::Configuration
    # Alphabetized to more easily lookup particular preferences
    preference :address_requires_state, :boolean, default: true # should state/state_name be required
    # preference :address_requires_phone, :boolean, default: true # Determines whether we require phone in address
    preference :admin_interface_logo, :string, default: 'admin/logo.png'
    # preference :admin_path, :string, default: '/admin'
    # preference :admin_products_per_page, :integer, default: Kaminari.config.default_per_page
    preference :admin_products_per_page, :integer, default: 50
    preference :admin_variants_per_page, :integer, default: 10
    preference :admin_orders_per_page, :integer, default: 50
    preference :admin_properties_per_page, :integer, default: Kaminari.config.default_per_page
    # preference :admin_promotions_per_page, :integer, default: Kaminari.config.default_per_page
    # preference :admin_customer_returns_per_page, :integer, default: Kaminari.config.default_per_page
    preference :admin_users_per_page, :integer, default: 50
    # preference :admin_show_version, :boolean, default: true
    preference :allow_checkout_on_gateway_error, :boolean, default: false
    preference :allow_guest_checkout, :boolean, default: true
    preference :allow_return_item_amount_editing, :boolean, default: false
    preference :alternative_billing_phone, :boolean, default: false
    preference :alternative_shipping_phone, :boolean, default: false # Request extra phone for ship addr
    # preference :always_include_confirm_step, :boolean, default: false # Ensures confirmation step is always in checkout_progress bar, but does not force a confirm step if your payment methods do not support it.
    preference :always_put_site_name_in_title, :boolean, default: true
    preference :title_site_name_separator, :string, default: '-' # When always_put_site_name_in_title is true, insert a separator character before the site name in the title
    preference :auto_capture, :boolean, default: false # automatically capture the credit card (as opposed to just authorize and capture later)
    preference :auto_capture_on_dispatch, :boolean, default: false # Captures payment for each shipment in Shipment#after_ship callback, and makes Shipment.ready when payment authorized.
    preference :binary_inventory_cache, :boolean, default: false # only invalidate product cache when a stock item changes whether it is in_stock
    preference :checkout_zone, :string, default: nil # replace with the name of a zone if you would like to limit the countries
    preference :company, :boolean, default: false # Request company field for billing and shipping addr
    preference :currency, :string, default: 'USD'
    preference :default_country_id, :integer
    preference :default_country_iso, :string, default: 'US'
    preference :expedited_exchanges, :boolean, default: false # NOTE this requires payment profiles to be supported on your gateway of choice as well as a delayed job handler to be configured with activejob. kicks off an exchange shipment upon return authorization save. charge customer if they do not return items within timely manner.
    preference :expedited_exchanges_days_window, :integer, default: 14 # the amount of days the customer has to return their item after the expedited exchange is shipped in order to avoid being charged
    preference :layout, :string, default: 'spree/layouts/spree_application'
    preference :logo, :string, default: 'logo/spree_50.png'
    preference :order_bill_address_used, :boolean, default: true
    preference :max_level_in_taxons_menu, :integer, default: 1 # maximum nesting level in taxons menu
    preference :products_per_page, :integer, default: 12
    preference :require_master_price, :boolean, default: true
    preference :restock_inventory, :boolean, default: true # Determines if a return item is restocked automatically once it has been received
    preference :return_eligibility_number_of_days, :integer, default: 365
    preference :send_core_emails, :boolean, default: true # Default mail headers settings
    preference :mails_from, :string, default: 'spree@example.com'
    preference :shipping_instructions, :boolean, default: false # Request instructions/info for shipping
    preference :show_only_complete_orders_by_default, :boolean, default: true
    preference :show_variant_full_price, :boolean, default: false # Displays variant full price or difference with product price. Default false to be compatible with older behavior
    preference :show_products_without_price, :boolean, default: false
    preference :show_raw_product_description, :boolean, default: false
    preference :tax_using_ship_address, :boolean, default: true
    preference :track_inventory_levels, :boolean, default: true # Determines whether to track on_hand values for variants / products.

    # Store credits configurations
    # preference :non_expiring_credit_types, :array, default: []
    preference :credit_to_new_allocation, :boolean, default: false

    preference :automatic_default_address, :boolean, default: true

    # searcher_class allows spree extension writers to provide their own Search class
    class_name_attribute :searcher_class, default: 'Spree::Core::Search::Base'

    class_name_attribute :variant_price_selector_class, default: 'Spree::Variant::PriceSelector'

    delegate :pricing_options_class, to: :variant_price_selector_class

    def default_pricing_options
      pricing_options_class.new
    end

    class_name_attribute :variant_search_class, default: 'Spree::Core::Search::Variant'

    class_name_attribute :promotion_chooser_class, default: 'Spree::PromotionChooser'

    class_name_attribute :shipping_rate_sorter_class, default: 'Spree::Stock::ShippingRateSorter'

    class_name_attribute :shipping_rate_selector_class, default: 'Spree::Stock::ShippingRateSelector'

    class_name_attribute :shipping_rate_tax_calculator_class, default: 'Spree::TaxCalculator::ShippingRate'

    class_name_attribute :order_mailer_class, default: 'Spree::OrderMailer'

    class_name_attribute :reimbursement_mailer_class, default: 'Spree::ReimbursementMailer'

    class_name_attribute :order_merger_class, default: 'Spree::OrderMerger'

    class_name_attribute :default_payment_builder_class, default: 'Spree::Wallet::DefaultPaymentBuilder'

    # Allows providing your own class for canceling payments.
    #
    # @!attribute [rw] payment_canceller
    # @return [Class] a class instance that responds to `cancel!(payment)`
    attr_writer :payment_canceller
    def payment_canceller
      @payment_canceller ||= Spree::Payment::Cancellation.new(
        reason: Spree::Payment::Cancellation::DEFAULT_REASON
      )
    end

    # Allows providing your own class for adding payment sources to a user's
    # "wallet" after an order moves to the complete state.
    #
    # @!attribute [rw] add_payment_sources_to_wallet_class
    # @return [Class] a class with the same public interfaces
    #   as Spree::Wallet::AddPaymentSourcesToWallet.
    class_name_attribute :add_payment_sources_to_wallet_class, default: 'Spree::Wallet::AddPaymentSourcesToWallet'

    # Allows providing your own class for calculating taxes on an order.
    #
    # This extension point is under development and may change in a future minor release.
    #
    # @!attribute [rw] tax_adjuster_class
    # @return [Class] a class with the same public interfaces as
    #   Spree::Tax::OrderAdjuster
    # @api experimental
    class_name_attribute :tax_adjuster_class, default: 'Spree::Tax::OrderAdjuster'

    # Allows providing your own class for calculating taxes on an order.
    #
    # @!attribute [rw] tax_calculator_class
    # @return [Class] a class with the same public interfaces as
    #   Spree::TaxCalculator::Default
    # @api experimental
    class_name_attribute :tax_calculator_class, default: 'Spree::TaxCalculator::Default'

    # Allows providing your own class for choosing which store to use.
    #
    # @!attribute [rw] current_store_selector_class
    # @return [Class] a class with the same public interfaces as
    #   Spree::CurrentStoreSelector
    class_name_attribute :current_store_selector_class, default: 'Spree::StoreSelector::ByServerName'

    # Allows providing your own class for creating urls on taxons
    #
    # @!attribute [rw] taxon_url_parametizer_class
    # @return [Class] a class that provides a `#parameterize` method that
    # returns a String
    class_name_attribute :taxon_url_parametizer_class, default: 'ActiveSupport::Inflector'

    # Allows providing your own class instance for generating order numbers.
    #
    # @!attribute [rw] order_number_generator
    # @return [Class] a class instance with the same public interfaces as
    #   Spree::Order::NumberGenerator
    # @api experimental
    attr_writer :order_number_generator
    def order_number_generator
      @order_number_generator ||= Spree::Order::NumberGenerator.new
    end

    def static_model_preferences
      @static_model_preferences ||= Spree::Preferences::StaticModelPreferences.new
    end

    def stock
      @stock_configuration ||= Spree::Core::StockConfiguration.new
    end

    def roles
      @roles ||= Spree::RoleConfiguration.new.tap do |roles|
        roles.assign_permissions :default, ['Spree::PermissionSets::DefaultCustomer']
        roles.assign_permissions :admin, ['Spree::PermissionSets::SuperUser']
      end
    end

    def environment
      @environment ||= Spree::Core::Environment.new(self).tap do |env|
        env.calculators.shipping_methods = %w[
          Spree::Calculator::Shipping::FlatPercentItemTotal
          Spree::Calculator::Shipping::FlatRate
          Spree::Calculator::Shipping::FlexiRate
          Spree::Calculator::Shipping::PerItem
          Spree::Calculator::Shipping::PriceSack
        ]

        env.calculators.tax_rates = %w[
          Spree::Calculator::DefaultTax
        ]

        env.stock_splitters = %w[
          Spree::Stock::Splitter::ShippingCategory
          Spree::Stock::Splitter::Backordered
        ]

        env.payment_methods = %w[
          Spree::PaymentMethod::BogusCreditCard
          Spree::PaymentMethod::SimpleBogusCreditCard
          Spree::PaymentMethod::StoreCredit
          Spree::PaymentMethod::Check
        ]

        env.promotions = Spree::Promo::Environment.new.tap do |promos|
          promos.rules = %w[
            Spree::Promotion::Rules::ItemTotal
            Spree::Promotion::Rules::Product
            Spree::Promotion::Rules::User
            Spree::Promotion::Rules::FirstOrder
            Spree::Promotion::Rules::UserLoggedIn
            Spree::Promotion::Rules::OneUsePerUser
            Spree::Promotion::Rules::Taxon
            Spree::Promotion::Rules::NthOrder
            Spree::Promotion::Rules::OptionValue
            Spree::Promotion::Rules::FirstRepeatPurchaseSince
            Spree::Promotion::Rules::UserRole
            Spree::Promotion::Rules::Store
          ]

          promos.actions = %w[
            Spree::Promotion::Actions::CreateAdjustment
            Spree::Promotion::Actions::CreateItemAdjustments
            Spree::Promotion::Actions::CreateQuantityAdjustments
            Spree::Promotion::Actions::FreeShipping
          ]

          promos.shipping_actions = %w[
            Spree::Promotion::Actions::FreeShipping
          ]
        end

        env.calculators.promotion_actions_create_adjustments = %w[
          Spree::Calculator::FlatPercentItemTotal
          Spree::Calculator::FlatRate
          Spree::Calculator::FlexiRate
          Spree::Calculator::TieredPercent
          Spree::Calculator::TieredFlatRate
        ]

        env.calculators.promotion_actions_create_item_adjustments = %w[
          Spree::Calculator::DistributedAmount
          Spree::Calculator::FlatRate
          Spree::Calculator::FlexiRate
          Spree::Calculator::PercentOnLineItem
          Spree::Calculator::TieredPercent
        ]

        env.calculators.promotion_actions_create_quantity_adjustments = %w[
          Spree::Calculator::PercentOnLineItem
          Spree::Calculator::FlatRate
        ]
      end
    end
  end
end
