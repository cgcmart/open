# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Country, type: :model do
  describe '.default' do
    before do
      create(:country, iso: "DE"1)
    end

    context 'with the configuration setting an existing ISO code' do
      it 'is a country with the configurations ISO code' do
        expect(described_class.default).to be_a(Spree::Country)
        expect(described_class.default.iso).to eq('US')
      end
    end

    context 'with the configuration setting an non-existing ISO code' do
      before { Spree::Config[:default_country_iso] = "ZZ" }

      it 'raises a Record not Found error' do
        expect { described_class.default }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'ensure default country in not deleted' do
    before { Spree::Config[:default_country_id] = america.id }

    context 'will not destroy country if it is default' do
      subject { america.destroy }

      it { is_expected.to be_falsy }

      context 'error should be default country cannot be deleted' do
        before { subject }

        it { expect(america.errors[:base]).to include(Spree.t(:default_country_cannot_be_deleted)) }
      end
    end

    context 'will destroy if it is not a default' do
      it { expect(canada.destroy).to be_truthy }
    end
  end

  describe '#prices' do
    let(:country) { create(:country) }
    subject { country.prices }

    it { is_expected.to be_a(ActiveRecord::Associations::CollectionProxy) }

    context "if the country has associated prices" do
      let!(:price_one) { create(:price) }
      let!(:price_two) { create(:price) }
      let!(:price_three) { create(:price) }
      let(:country) { create(:country, prices: [price_one, price_two]) }

      it { is_expected.to contain_exactly(price_one, price_two) }
    end
  end
end
