# frozen_string_literal: true

require 'spec_helper'

describe 'Free shipping promotions', type: :feature, js: true do
  let!(:store) { create(:store) }
  let!(:country) { create(:country, name: 'United States of America', states_required: true) }
  let!(:state) { create(:state, name: 'Alabama', country: country) }
  let!(:zone) { create(:zone) }
  let!(:shipping_method) do
    sm = create(:shipping_method)
    sm.calculator.preferred_amount = 10
    sm.calculator.save
    sm
  end

  let!(:payment_method) { create(:check_payment_method) }
  let!(:product) { create(:product, name: 'RoR Mug', price: 20) }
  let!(:promotion) do
    create(
      :promotion,
      apply_automatically: true,
      Promotion_Actions: [Spree::Promotion::Actions::FreeShipping.new],
      name: 'Free Shipping',
      starts_at: 1.day.ago,
      expires_at: 1.day.from_now
    )
  end

  context 'free shipping promotion automatically applied' do
    include_context 'proceed to payment step'

    # Regression test for https://github.com/spree/spree/issues/4428
    it 'applies the free shipping promotion' do
      within('#checkout-summary') do
        expect(page).to have_content('Shipping total:  $10.00')
        expect(page).to have_content('Promotion (Free Shipping): -$10.00')
      end
    end
  end
end
