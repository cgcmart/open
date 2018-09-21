# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ShipmentMailer, type: :mailer do
  let(:order) { stub_model(Spree::Order, number: 'R12345') }
  let(:shipping_method) { stub_model(Spree::ShippingMethod, name: 'USPS') }
  let(:product) { stub_model(Spree::Product, name: %{The "BEST" product}, sku: 'SKU0001') }
  let(:variant) { stub_model(Spree::Variant, product: product) }
  let(:line_item) { stub_model(Spree::LineItem, variant: variant, order: order, quantity: 1, price: 5) }
  let(:shipment) do
    shipment = stub_model(Spree::Shipment)
    allow(shipment).to receive_messages(line_items: [line_item], order: order)
    allow(shipment).to receive_messages(tracking_url: 'http://track.com/me')
    allow(shipment).to receive_messages(shipping_method: shipping_method)
    shipment
  end

  # Regression test for https://github.com/spree/spree/issues/2196
  it "doesn't include out of stock in the email body" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment)
    expect(shipment_email.parts.first.body).not_to include(%q{Out of Stock})
    expect(shipment_email.parts.first.body).to include(%{Your order has been shipped})
    expect(shipment_email.subject).to eq "#{order.store.name} Shipment Notification ##{order.number}"
  end

  context 'with resend option' do
    subject do
      Spree::ShipmentMailer.shipped_email(shipment, resend: true).subject
    end
    it { is_expected.to match /^\[RESEND\] / }
  end

  context 'emails must be translatable' do
    context 'shipped_email' do
      context 'pt-BR locale' do
        before do
          pt_br_shipped_email = { spree: { shipment_mailer: { shipped_email: { dear_customer: 'Caro Cliente,' } } } }
          I18n.backend.store_translations :'pt-BR', pt_br_shipped_email
          I18n.locale = :'pt-BR'
        end

        after do
          I18n.locale = I18n.default_locale
        end

        specify do
          shipped_email = Spree::ShipmentMailer.shipped_email(shipment)
          expect(shipped_email).to have_body_text('Caro Cliente,')
        end
      end
    end
  end
end
