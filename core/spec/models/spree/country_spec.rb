# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Country, type: :model do
  describe '.by_iso' do
    let(:dummy_iso) { 'XY' }

    it 'will return Country by iso' do
      expect(described_class.by_iso(america.iso)).to eq america
    end

    it 'will return Country by iso3' do
      expect(described_class.by_iso(america.iso3)).to eq america
    end

    it 'will return nil with wrong iso or iso3' do
      expect(described_class.by_iso(dummy_iso)).to eq nil
    end

    it 'will return Country by lower iso' do
      expect(described_class.by_iso(america.iso.downcase)).to eq america
    end
  end

  describe '.default' do
    before do
      create(:country, iso: 'DE')
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
    before { Spree::Config[:default_country_iso] = america.iso }

    context 'will not destroy country if it is default' do
      subject { america.destroy }

      it { is_expected.to be_falsy }

      context 'error should be default country cannot be deleted' do
        before { subject }

        it { expect(america.errors[:base]).to include(t('spree.default_country_cannot_be_deleted')) }
      end
    end

    context 'will destroy if it is not a default' do
      it { expect(canada.destroy).to be_truthy }
    end
  end

  context '#default?' do
    before { Spree::Config[:default_country_iso] = america.iso }

    it 'returns true for default country' do
      expect(america.default?).to eq(true)
    end

    it 'returns false for other countries' do
      expect(canada.default?).to eq(false)
    end
  end

  describe '.available' do
    let!(:united_states) { create(:country, iso: 'US') }
    let!(:canada) { create(:country, iso: 'CA') }
    let!(:italy) { create(:country, iso: 'IT') }
    let!(:custom_zone) { create(:zone, name: 'Custom Zone', countries: [united_states, italy]) }

    context 'with a checkout zone defined' do
      context 'when checkout zone is of type country' do
        let!(:checkout_zone) { create(:zone, name: 'Checkout Zone', countries: [united_states, canada]) }

        before do
          Spree::Config.checkout_zone = checkout_zone.name
        end

        context 'with no arguments' do
          it 'returns "Checkout Zone" countries' do
            expect(described_class.available).to contain_exactly(united_states, canada)
          end
        end

        context 'setting nil as restricting zone' do
          it 'returns all countries' do
            expect(described_class.available(restrict_to_zone: nil)).to contain_exactly(united_states, canada, italy)
          end
        end

        context 'setting "Custom Zone" as restricting zone' do
          it 'returns "Custom Zone" countries' do
            expect(described_class.available(restrict_to_zone: 'Custom Zone')).to contain_exactly(united_states, italy)
          end
        end

        context 'setting "Checkout Zone" as restricting zone' do
          it 'returns "Checkout Zone" countries' do
            expect(described_class.available(restrict_to_zone: 'Checkout Zone')).to contain_exactly(united_states, canada)
          end
        end
      end

      context 'when checkout zone is of type state' do
        let!(:state) { create(:state, country: united_states) }
        let!(:checkout_zone) { create(:zone, name: 'Checkout Zone', states: [state]) }

        before do
          Spree::Config[:checkout_zone] = checkout_zone.name
        end

        context 'with no arguments' do
          it 'returns all countries' do
            expect(described_class.available(restrict_to_zone: nil)).to contain_exactly(united_states, canada, italy)
          end
        end
      end
    end

    context 'with no checkout zone defined' do
      context 'with no arguments' do
        it 'returns all countries' do
          expect(described_class.available).to contain_exactly(united_states, canada, italy)
        end
      end

      context 'setting nil as restricting zone' do
        it 'returns all countries' do
          expect(described_class.available(restrict_to_zone: nil)).to contain_exactly(united_states, canada, italy)
        end
      end

      context 'setting "Custom Zone" as restricting zone' do
        it 'returns "Custom Zone" countries' do
          expect(described_class.available(restrict_to_zone: 'Custom Zone')).to contain_exactly(united_states, italy)
        end
      end
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