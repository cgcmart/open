# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ReturnAuthorization, type: :model do
  let(:order) { create(:shipped_order) }
  let(:stock_location) { create(:stock_location) }
  let(:rma_reason) { create(:return_reason) }
  let(:inventory_unit_1) { order.inventory_units.first }

  let(:variant) { order.variants.first }
  let(:return_authorization) do
    Spree::ReturnAuthorization.new(order: order,
                                   stock_location_id: stock_location.id,
                                   return_reason_id: rma_reason.id)
  end

  context 'save' do
    let(:order) { Spree::Order.create }

    it 'is invalid when order has no inventory units' do
      order.inventory_units.each(&:delete)
      return_authorization.save
      expect(return_authorization.errors[:order]).to eq(['has no shipped units'])
    end

    context 'an inventory unit is already being exchanged' do
      let(:order)                           { create(:shipped_order, line_items_count: 2) }
      let!(:previous_exchange_return_item)  { create(:exchange_return_item, inventory_unit: order.inventory_units.last) }
      let(:return_item)                     { create(:return_item, inventory_unit: order.inventory_units.last) }
      let(:return_authorization)            { build(:return_authorization, order: order, return_items: [return_item]) }

      it 'is invalid' do
        return_authorization.save
        expect(return_authorization.errors['base']).to include('Return items cannot be created for inventory units that are already awaiting exchange.')
      end
    end

    context 'an inventory unit is not being exchanged' do
      let(:order)                           { create(:shipped_order, line_items_count: 2) }
      let(:return_item)                     { create(:return_item, inventory_unit: order.inventory_units.last) }
      let(:return_authorization)            { build(:return_authorization, order: order, return_items: [return_item]) }

      it 'is valid' do
        return_authorization.save
        expect(return_authorization.errors['base'].size).to eq 0
      end
    end
end

  describe '.before_create' do
    describe '#generate_number' do
      context 'number is assigned' do
        let(:return_authorization) { Spree::ReturnAuthorization.new(number: '123') }

        it 'returns the assigned number' do
          return_authorization.save
          expect(return_authorization.number).to eq('123')
        end
      end

      context 'number is not assigned' do
        let(:return_authorization) { Spree::ReturnAuthorization.new(number: nil) }

        before { allow(return_authorization).to receive_messages valid?: true }

        it 'assigns number with random RA number' do
          return_authorization.save
          expect(return_authorization.number).to match(/RA\d{9}/)
        end
      end
    end
  end

  describe 'whitelisted_ransackable_attributes' do
    it { expect(Spree::ReturnAuthorization.whitelisted_ransackable_attributes).to eq(%w(memo number state)) }
  end

  context '#currency' do
    before { allow(order).to receive(:currency) { 'ABC' } }

    it 'returns the order currency' do
      expect(return_authorization.currency).to eq('ABC')
    end
  end

  describe '#total' do
    subject { return_authorization.reload.total }

    let(:amount_1) { 15.0 }
    let!(:return_item_1) { create(:return_item, return_authorization: return_authorization, amount: amount_1) }

    let(:amount_2) { 50.0 }
    let!(:return_item_2) { create(:return_item, return_authorization: return_authorization, amount: amount_2) }

    let(:amount_3) { 5.0 }
    let!(:return_item_3) { create(:return_item, return_authorization: return_authorization, amount: amount_3) }

    it "sums it's associated return_item's amounts" do
      expect(subject).to eq(amount_1 + amount_2 + amount_3)
    end
  end

  describe '#display_total' do
    it 'returns a Spree::Money' do
      allow(return_authorization).to receive_messages(total: 21.22)
      expect(return_authorization.display_total).to eq(Spree::Money.new(21.22))
    end
  end

  describe '#amount' do
    subject { return_authorization.amount }

    let(:return_item1) { create(:return_item, amount: 10) }
    let(:return_item2) { create(:return_item, amount: 5) }
    let(:return_authorization) { create(:return_authorization, return_items: [return_item1, return_item2]) }

    it "sums the return items' amounts" do
      expect(subject).to eq(15)
    end
  end

  describe '#refundable_amount' do
    subject { return_authorization.refundable_amount }

    let(:line_item_price) { 5.0 }
    let(:line_item_count) { return_authorization.order.line_items.count }

    before do
      return_authorization.order.line_items.update_all(price: line_item_price)
      return_authorization.order.update_attribute(:promo_total, promo_total)
    end

    context 'no promotions' do
      let(:promo_total) { 0.0 }

      it 'returns the pre-tax line item total' do
        expect(subject).to eq(line_item_price * line_item_count)
      end
    end

    context 'promotions' do
      let(:promo_total) { -10.0 }

      it 'returns the pre-tax line item total minus the order level promotion value' do
        expect(subject).to eq((line_item_price * line_item_count) + promo_total)
      end
    end
  end

  describe '#customer_returned_items?' do
    subject { return_authorization.customer_returned_items? }

    before do
      allow_any_instance_of(Spree::Order).to receive_messages(return!: true)
    end

    context 'has associated customer returns' do
      let(:customer_return) { create(:customer_return) }
      let(:return_authorization) { customer_return.return_authorizations.first }

      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'does not have associated customer returns' do
      let(:return_authorization) { create(:return_authorization) }

      it 'returns false' do
        expect(subject).to eq false
      end
    end
  end

  describe 'cancel_return_items' do
    subject {
      return_authorization.cancel!
    }

    let(:return_authorization) { create(:return_authorization, return_items: return_items) }
    let(:return_items) { [return_item] }
    let(:return_item) { create(:return_item) }

    it 'cancels the associated return items' do
      subject
      expect(return_item.reception_status).to eq 'cancelled'
    end

    context 'some return items cannot be cancelled' do
      let(:return_items) { [return_item, return_item_2] }
      let(:return_item_2) { create(:return_item, reception_status: 'received') }

      it 'cancels those that can be cancelled' do
        subject
        expect(return_item.reception_status).to eq 'cancelled'
        expect(return_item_2.reception_status).to eq 'received'
      end
    end
  end

  describe '#can_cancel?' do
    subject { create(:return_authorization, return_items: return_items).can_cancel? }

    let(:return_items) { [return_item_1, return_item_2] }
    let(:return_item_1) { create(:return_item) }
    let(:return_item_2) { create(:return_item) }

    context 'all items can be cancelled' do
      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'at least one return item can be cancelled' do
      let(:return_item_2) { create(:return_item, reception_status: 'received') }

      it { is_expected.to eq true }
    end

    context 'no items can be cancelled' do
      let(:return_item_1) { create(:return_item, reception_status: 'received') }
      let(:return_item_2) { create(:return_item, reception_status: 'received') }

      it { is_expected.to eq false }
    end

    context 'when return_authorization has no return_items' do
      let(:return_items) { [] }

      it { is_expected.to eq true }
    end
  end
end
