# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::RootController do
  describe 'GET index' do
    subject { get :index }

    let(:user) { build(:user) }
    let(:ability) { Spree::Ability.new(user) }

    before do
      allow_any_instance_of(Spree::Admin::RootController).to receive(:try_spree_current_user).and_return(user)
      allow_any_instance_of(Spree::Admin::RootController).to receive(:current_ability).and_return(ability)
    end

    context 'when a user can admin and display spree orders' do
      before do
        ability.can :admin, Spree::Order
        ability.can :display, Spree::Order
      end

      it { is_expected.to redirect_to(spree.admin_orders_path) }
    end
  end
end
