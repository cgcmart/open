# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coupon code promotions', type: :feature, js: true do
  let!(:store) { create(:store) }
  let!(:country) { create(:country, name: 'United States of America', states_required: true) }
  let!(:state) { create(:state, name: 'Alabama', country: country) }
  let!(:zone) { create(:zone) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:product) { create(:product, name: 'RoR Mug', price: 20) }

  context 'visitor makes checkou as guest without registrationt' do
    def create_basic_coupon_promotion(code)
      promotion = Spree::Promotion.create!(
        name: code.titleize,
        code: code,
        starts_at: 1.day.ago,
        expires_at: 1.day.from_now
      )

      calculator = Spree::Calculator::FlatRate.new
      calculator.preferred_amount = 10

      action = Spree::Promotion::Actions::CreateItemAdjustments.new
      action.calculator = calculator
      action.promotion = promotion
      action.save

      promotion.reload # so that promotion.actions is available
    end

    let!(:promotion) { create_basic_coupon_promotion('onetwo') }

    # OrdersController
    context 'on the payment page' do
      include_context 'proceed to payment step'

      it 'informs about an invalid coupon code' do
        fill_in 'coupon_code', with: 'coupon_codes_rule_man'
        click_button 'Apply Code'
        expect(page).to have_content(I18n.t('spree.coupon_code_not_found'))
      end

      it 'informs the user about a coupon code which has exceeded its usage' do
        promotion.update_column(:usage_limit, 5)
        allow_any_instance_of(promotion.class).to receive_messages(credits_count: 10)

        fill_in 'coupon_code', with: 'onetwo'
        click_button 'Save and Continue'
        expect(page).to have_content(I18n.t('spree.coupon_code_max_usage'))
      end

      it 'can enter an invalid coupon code, then a real one' do
        fill_in 'coupon_code', with: 'coupon_codes_rule_man'
        click_button 'Apply Code'
        expect(page).to have_content(t('spree.coupon_code_not_found'))
        fill_in 'coupon_code', with: 'onetwo'
        click_button 'Apply Code'
        expect(page).to have_content('Promotion (Onetwo)   -$10.00')
      end

      context 'with a promotion' do
        it 'applies a promotion to an order' do
          fill_in 'coupon_code', with: 'onetwo'
          click_button 'Apply Code'
          expect(page).to have_content('Promotion (Onetwo)   -$10.00')
        end
      end
    end
  end
end
