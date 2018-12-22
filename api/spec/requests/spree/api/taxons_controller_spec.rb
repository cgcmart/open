# frozen_string_literal: true

require 'spec_helper'

def expect_single_taxon_result(taxon_name)
  expect(json_response['taxons'].count).to eq(1)
  expect(json_response['taxons'].first['name']).to eq(taxon_name)
end

module Spree
  describe Api::TaxonsController, type: :request do
    render_views

    let!(:taxonomy) { create(:taxonomy) }
    let!(:taxon) { create(:taxon, name: 'Ruby', taxonomy: taxonomy, parent_id: taxonomy.root.id) }
    let!(:rust_taxon) { create(:taxon, name: 'Rust', taxonomy: taxonomy, parent_id: taxonomy.root.id) }
    let!(:taxon2) { create(:taxon, name: 'Rails', taxonomy: taxonomy, parent_id: taxon.id) }
    let(:attributes) { ['id', 'name', 'pretty_name', 'permalink', 'parent_id', 'taxonomy_id', 'meta_title', 'meta_description'] }

    before do
      create(:taxon, name: 'React', taxonomy: taxonomy, parent_id: taxon2.id) # taxon3
      stub_authentication!
    end

    context 'as a normal user' do
      it 'gets all taxons for a taxonomy' do
        get spree.api_taxonomy_taxons_path(taxonomy)
        expect(json_response['taxons'].first['name']).to eq taxon.name
        children = json_response['taxons'].first['taxons']
        expect(children.count).to eq 1
        expect(children.first['name']).to eq taxon2.name
        expect(children.first['taxons'].count).to eq 1
      end

      # Regression test for https://github.com/spree/spree/issues/4112
      it 'does not include children when asked not to' do
        get spree.api_taxonomy_taxons_path(taxonomy), params: { without_children: 1 }

        expect(json_response['taxons'].first['name']).to eq(taxon.name)
        expect(json_response['taxons'].first['taxons']).to be_nil
      end

      it 'paginates through taxons' do
        new_taxon = create(:taxon, name: 'Go', taxonomy: taxonomy, parent_id: taxonomy.root.id)
        taxonomy.root.children << new_taxon
        expect(taxonomy.root.children.count).to eq(3)
        get spree.api_taxonomy_taxons_path(taxonomy), taxonomy_id: taxonomy_id, params: { page: 1, per_page: 1 }
        expect(json_response['count']).to eq(1)
        expect(json_response['total_count']).to eq(3)
        expect(json_response['current_page']).to eq(1)
        expect(json_response['per_page']).to eq(1)
        expect(json_response['pages']).to eq(3)
      end

      describe 'searching' do
        context 'with a name' do
          before do
            get spree.api_taxons_path, params: { q: { name_cont: name } }
          end

          context 'with one result' do
            let(:name) { 'Ruby' }

            it 'returns an array including the matching taxon' do
              expect(json_response['taxons'].count).to eq(1)
              expect(json_response['taxons'].first['name']).to eq 'Ruby'
            end
          end

          context 'with no results' do
            let(:name) { "Imaginary" }

            it 'returns an empty array of taxons' do
              expect(json_response.keys).to include('taxons')
              expect(json_response['taxons'].count).to eq(0)
            end
          end
        end

        context 'with no filters' do
          it 'gets all taxons' do
            get spree.api_taxons_path
            expect(json_response['taxons'].first['name']).to eq taxonomy.root.name
            children = json_response['taxons'].first['taxons']
            expect(children.count).to eq 1
            expect(children.first['name']).to eq taxon.name
            expect(children.first['taxons'].count).to eq 1
          end
        end
      end

      it 'gets a single taxon' do
        get spree.api_taxonomy_taxon_path(taxonomy_id, taxon.id)

        expect(json_response['name']).to eq taxon.name
        expect(json_response['taxons'].count).to eq 1
      end

      it 'can learn how to create a new taxon' do
        get spree.new_api_taxonomy_taxon_path(taxonomy_id)
        expect(json_response['attributes']).to eq(attributes.map(&:to_s))
        required_attributes = json_response['required_attributes']
        expect(required_attributes).to include('name')
      end

      it 'cannot create a new taxon if not an admin' do
        post spree.api_taxonomy_taxons_path(taxonomy_id), params: { taxon: { name: 'Location' } }
        assert_unauthorized!
      end

      it 'cannot update a taxon' do
        put spree.api_taxonomy_taxon_path(taxonomy_id, taxon.id), params: { taxon: { name: 'I hacked your store!' } }
        assert_unauthorized!
      end

      it 'cannot delete a taxon' do
        delete spree.api_taxonomy_taxon_path(taxonomy_id, taxon.id)
        assert_unauthorized!
      end

      context "with caching enabled" do
        let!(:product) { create(:product, taxons: [taxon]) }

        before do
          ActionController::Base.perform_caching = true
        end

        it "handles exclude_data correctly" do
          get spree.api_taxon_products_path, params: { id: taxon.id, simple: true }
          expect(response).to be_successful
          simple_response = json_response

          get spree.api_taxon_products_path, params: { id: taxon.id }
          expect(response).to be_successful
          full_response = json_response

          expect(simple_response["products"][0]["description"]).to be_nil
          expect(full_response["products"][0]["description"]).not_to be_nil
        end

        after do
          ActionController::Base.perform_caching = false
        end
      end
    end

    context 'as an admin' do
      sign_in_as_admin!

      it 'can create' do
        post spree.api_taxonomy_taxons_path(taxonomy_id), params: { taxon: { name: 'Colors' } }
        expect(json_response).to have_attributes(attributes)
        expect(response.status).to eq(201)

        expect(taxonomy.reload.root.children.count).to eq 2
        taxon = Spree::Taxon.where(name: 'Colors').first

        expect(taxon.parent_id).to eq taxonomy.root.id
        expect(taxon.taxonomy_id).to eq taxonomy.id
      end

      it 'can update the position in the list' do
        taxonomy.root.children << taxon2
        put spree.api_taxonomy_taxon_path(taxonomy_id, taxon.id), params: { taxon: { parent_id: taxon.parent_id, child_index: 2 } }
        expect(response.status).to eq(200)
        expect(taxonomy.reload.root.children[0]).to eql taxon2
        expect(taxonomy.reload.root.children[1]).to eql taxon
      end

      it 'cannot create a new taxon with invalid attributes' do
        post spree.api_taxonomy_taxons_path(taxonomy_id), params: { taxon: { foo: :bar } }
        expect(response.status).to eq(422)
        expect(json_response['error']).to eq('Invalid resource. Please fix errors and try again.')
        expect(taxonomy.reload.root.children.count).to eq 1
      end

      it 'cannot create another root taxon' do
        post spree.api_taxonomy_taxons_path(taxonomy_id), params: {  taxon: { name: 'foo', parent_id: nil } }
        expect(json_response[:errors][:root_conflict].first).to eq 'this taxonomy already has a root taxon'
      end

      it 'cannot create a new taxon with invalid taxonomy_id' do
        post spree.api_taxonomy_taxons_path(1000), params: { taxon: { name: 'Colors' } }
        expect(response.status).to eq(422)
        expect(json_response['error']).to eq('Invalid resource. Please fix errors and try again.')

        errors = json_response['errors']
        expect(errors['taxonomy_id']).not_to be_nil
        expect(errors['taxonomy_id'].first).to eq 'Invalid taxonomy id.'

        expect(taxonomy.reload.root.children.count).to eq 1
      end

      it 'can destroy' do
        delete spree.api_taxonomy_taxon_path(taxonomy, taxon.id)
        expect(response.status).to eq(204)
      end
    end
  end
end
