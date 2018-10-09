# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe FrontendHelper, type: :helper do
    # Regression test for https://github.com/spree/spree/issues/2759
    it 'nested_taxons_path works with a Taxon object' do
      taxon = create(:taxon, name: 'iphone')
      expect(spree.nested_taxons_path(taxon)).to eq("/t/#{taxon.parent.permalink}/#{taxon.name}")
    end

    context '#checkout_progress' do
      before do
        @order = create(:order, state: 'address')
      end

      it 'does not include numbers by default' do
        output = checkout_progress
        expect(output).not_to include('1.')
      end

      it 'has option to include numbers' do
        output = checkout_progress(numbers: true)
        expect(output).to include('1.')
      end
    end
  end
end
