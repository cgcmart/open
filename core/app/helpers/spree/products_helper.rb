# frozen_string_literal: true

module Spree
  module ProductsHelper
    # returns the formatted price for the specified variant as a full price or a difference depending on configuration
    def variant_price(variant)
      if Spree::Config[:show_variant_full_price]
        variant_full_price(variant)
      else
        variant_price_diff(variant)
      end
    end

    # returns the formatted price for the specified variant as a difference from product price
    def variant_price_diff(variant)
      return if variant_amount_same_as_master?(current_pricing_options)
      difference = variant.price_difference_from_master(current_pricing_options)
      absolute_amount = Spree::Money.new(difference.to_d.abs, currency: difference.currency.iso_code)
      i18n_key = difference.to_d > 0 ? :price_diff_add_html : :price_diff_subtract_html
      t(i18n_key, scope: [:spree, :helpers, :products], amount_html: absolute_amount.to_html)
    end

    # returns the formatted full price for the variant, if at least one variant price differs from product price
    def variant_full_price(variant)
      return if variant.product.variants.with_prices(current_pricing_options).all? { |v| v.price_same_as_master?(current_pricing_options) }
      variant.price_for(current_pricing_options).to_html
    end

    # converts line breaks in product description into <p> tags (for html display purposes)
    def product_description(product)
      if Spree::Config[:show_raw_product_description]
        raw(product.description)
      else
        raw(product.description.gsub(/(.*?)\r?\n\r?\n/m, '<p>\1</p>'))
      end

    def line_item_description_text(description_text)
      if description_text.present?
        truncate(strip_tags(description_text.gsub('&nbsp;', ' ')), length: 100)
      else
        t('spree.product_has_no_description')
      end
    end

    def cache_key_for_products
      count = @products.count
      max_updated_at = (@products.maximum(:updated_at) || Date.today).to_s(:number)
      "#{I18n.locale}/#{current_pricing_options.cache_key}/spree/products/all-#{params[:page]}-#{max_updated_at}-#{count}"
    end

    def cache_key_for_product(product = @product)
      (common_product_cache_keys + [product.cache_key_with_version, product.possible_promotions]).compact.join('/')
    end
  end
end
