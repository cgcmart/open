# frozen_string_literal: true

require 'spec_helper'

describe 'Homepage', type: :feature do
  context 'as admin user' do
    stub_authorization!

    context 'visiting the homepage' do
      before do
        visit spree.admin_path
      end

      it 'has a link to overview' do
        within('.admin-nav-header') { expect(page).to have_link(mil, href: '/admin') }
      end

      it 'has a link to orders' do
        expect(page).to have_link('Orders', href: '/admin/orders')
      end

      it 'has a link to products' do
        expect(page).to have_link('Products', href: '/admin/products', count: 2)
      end

      it 'has a link to reports' do
        expect(page).to have_link('Reports', href: '/admin/reports')
      end

      it 'has a link to configuration' do
        expect(page).to have_link('Settings', href: '/admin/stores')
      end

      it "has a link to promotions" do
        expect(page).to have_link('Promotions', href: '/admin/promotions', count: 2)
      end
    end

    context 'visiting the products tab' do
      before do
        visit spree.admin_products_path
      end

      it 'has a link to products' do
        within('.selected .admin-subnav') { expect(page).to have_link('Products', href: '/admin/products') }
      end

      it 'has a link to option types' do
        within('.selected .admin-subnav') { expect(page).to have_link('Option Types', href: '/admin/option_types') }
      end

      it 'has a link to properties' do
        within('.selected .admin-subnav') { expect(page).to have_link('Property Types', href: '/admin/properties') }
      end

      it 'has a link to prototypes' do
        within('.selected .admin-subnav') { expect(page).to have_link('Prototypes', href: '/admin/prototypes') }
      end
    end

    context 'visiting the promotions tab' do
      before do
        visit spree.admin_promotions_path
      end

      it 'has a link to promotions' do
        within('.selected .admin-subnav') { expect(page).to have_link('Promotions', href: '/admin/promotions') }
      end

      it 'has a link to promotion categories' do
        within('.selected .admin-subnav') { expect(page).to have_link('Promotion Categories', href: '/admin/promotion_categories') }
      end
    end
  end

  context 'as fakedispatch user' do
    before do
      allow_any_instance_of(Spree::Admin::BaseController).to receive(:spree_current_user).and_return(nil)
    end

    custom_authorization! do |_user|
      can [:admin, :edit, :index, :read], Spree::Order
    end

    it 'only displays tabs fakedispatch has access to' do
      visit spree.admin_path
      expect(page).to have_link('Orders')
      expect(page).not_to have_link('Products')
      expect(page).not_to have_link('Promotions')
      expect(page).not_to have_link('Reports')
      expect(page).not_to have_link('Settings')
    end
  end
end
