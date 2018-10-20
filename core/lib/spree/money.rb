# frozen_string_literal: true

Money.locale_backend = :i18n

module Spree
  # Spree::Money is a relatively thin wrapper around Monetize which handles
  # formatting via Spree::Config.
  class Money
    include Comparable
    DifferentCurrencyError = Class.new(StandardError)
    RUBY_NUMERIC_STRING = /\A-?\d+(\.\d+)?\z/

    class << self
      attr_accessor :default_formatting_rules

      def parse(amount, currency = Spree::Config[:currency])
        new(parse_to_money(amount, currency))
      end

      # @api private
      def parse_to_money(amount, currency)
        ::Monetize.parse(amount, currency)
      end
    end

    self.default_formatting_rules = {
      # Ruby money currently has this as false, which is wrong for the vast
      # majority of locales.
      sign_before_symbol: true
    }

    attr_reader :money

    delegate    :cents, :currency, :to_d, :zero?, to: :money

    # @param amount [Money, #to_s] the value of the money object
    # @param options [Hash] the default options for formatting the money object See #format
    def initialize(money, options = {})
      @money   = Spree::Money.parse([amount, (options[:currency] || Spree::Config[:currency])].join)
      @options = Spree::Money.default_formatting_rules.merge(options)
    end

    def amount_in_cents
      (cents / currency.subunit_to_unit.to_f * 100).round
    end

    def to_s
      money.format(options)
    end

    # 1) prevent blank, breaking spaces
    # 2) prevent escaping of HTML character entities
    def to_html(opts = { html_wrap: true })
      opts[:html_wrap] = opts[:html]
      opts.delete(:html)

      output = money.format(options.merge(opts))
      if opts[:html_wrap]
        output.gsub!(/<\/?[^>]*>/, '') # we don't want wrap every element in span
        output = output.sub(' ', '&nbsp;').html_safe
      end

      output
    end

    def as_json(*)
      to_s
    end

    def decimal_mark
      options[:decimal_mark] || money.decimal_mark
    end

    def thousands_separator
      options[:thousands_separator] || money.thousands_separator
    end

    def <=>(other)
      if !other.respond_to?(:money)
        raise TypeError, "Can't compare #{other.class} to Spree::Money"
      end
      if currency != other.currency
        # By default, ::Money will try to run a conversion on `other.money` and
        # try a comparison on that. We do not want any currency conversion to
        # take place so we'll catch this here and raise an error.
        raise(
          DifferentCurrencyError,
          "Can't compare #{currency} with #{other.currency}"
        )
      end
      @money <=> other.money
    end

    # Delegates comparison to the internal ruby money instance.
    #
    # @see http://www.rubydoc.info/gems/money/Money/Arithmetic#%3D%3D-instance_method
    def ==(other)
      raise TypeError, "Can't compare #{other.class} to Spree::Money" if !other.respond_to?(:money)
      @money == other.money
    end

    def -(other)
      raise TypeError, "Can't subtract #{other.class} to Spree::Money" if !other.respond_to?(:money)
      self.class.new(@money - other.money)
    end

    def +(other)
      raise TypeError, "Can't add #{other.class} to Spree::Money" if !other.respond_to?(:money)
      self.class.new(@money + other.money)
    end
  end
end
