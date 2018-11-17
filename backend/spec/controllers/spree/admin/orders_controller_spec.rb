# frozen_string_literal: true

require 'spec_helper'
require 'cancan'

RSpec.describe Spree::Admin::OrdersController, type: :controller do
  context 'with authorization' do
    stub_authorization!

    let(:order) do
      mock_model(
        Spree::Order,
        completed?:      true,
        total:           100,
        number:          'R123456789',
        all_adjustments: adjustments,
        billing_address: mock_model(Spree::Address)
      )
    end

    let(:adjustments) { double('adjustments') }
    let(:display_value) { Spree::ShippingMethod::DISPLAY_ON_BACK_END }

    before do
      request.env['HTTP_REFERER'] = 'http://localhost:3000'
      # ensure no respond_overrides are in effect
      Spree::BaseController.spree_responders[:OrdersController].clear if Spree::BaseController.spree_responders[:OrdersController].present?

      allow(Spree::Order).to receive_message_chain(:includes, find_by!: order)
      allow(order).to receive_messages(contents: Spree::OrderContents.new(order))
    end

    context '#approve' do
      it 'approves an order' do
        expect(order).to receive(:approved_by).with(controller.try_spree_current_user)
        spree_put :approve, id: order.number
        expect(flash[:success]).to eq I18n.t('spree.order_approved')
      end
    end

    context '#cancel' do
      it 'cancels an order' do
        expect(order).to receive(:canceled_by).with(controller.try_spree_current_user)
        spree_put :cancel, id: order.number
        expect(flash[:success]).to eq I18n.t('spree.order_canceled')
      end
    end

    context '#resume' do
      it 'resumes an order' do
        expect(order).to receive(:resume!)
        spree_put :resume, id: order.number
        expect(flash[:success]).to eq I18n.t('spree.order_resumed')
      end
    end

    context "#resend" do
      let(:order) { create(:completed_order_with_totals) }
      it "resends order email" do
        mail_message = double "Mail::Message"
        expect(Spree::OrderMailer).to receive(:confirm_email).with(order, true).and_return mail_message
        expect(mail_message).to receive :deliver_later
        post :resend, params: { id: order.number }
        expect(flash[:success]).to eq I18n.t('spree.order_email_resent')
      end
    end

    context 'pagination' do
      it 'can page through the orders' do
        spree_get :index, page: 2, per_page: 10
        expect(assigns[:orders].offset_value).to eq(10)
        expect(assigns[:orders].current_per_page).to eq(10)
      end
    end

    describe '#store' do
      subject do
        spree_get :store, id: cart_order.number
      end

      let(:cart_order) { create(:order_with_line_items) }

      it 'displays a page with stores select tag' do
        expect(subject).to render_template :store
      end
    end

    # Test for https://github.com/spree/spree/issues/3346
    context '#new' do
      let(:user) { create(:user) }
      before do
        allow(controller).to receive_messages spree_current_user: user
      end

      it 'imports a new order and sets the current user as a creator' do
        expect(Spree::Core::Importer::Order).to receive(:import)
          .with(nil, hash_including(created_by_id: controller.try_spree_current_user.id))
          .and_return(order)
        get :new
      end

      it 'sets frontend_viewable to false' do
        expect(Spree::Core::Importer::Order).to receive(:import)
          .with(nil, hash_including(frontend_viewable: false ))
          .and_return(order)
        get :new
      end

      it 'associates the order with a store' do
        expect(Spree::Core::Importer::Order).to receive(:import)
          .with(user, hash_including(store_id: controller.current_store.id))
          .and_return(order)
        get :new, params: { user_id: user.id }
      end

      context 'when a user_id is passed as a parameter' do
        let(:user)  { mock_model(Spree.user_class) }
        before { allow(Spree.user_class).to receive_messages find_by: user }

        it 'imports a new order and assigns the user to the order' do
          expect(Spree::Core::Importer::Order).to receive(:import)
            .with(user, hash_including(created_by_id: controller.try_spree_current_user.id))
            .and_return(order)
          get :new, params: { user_id: user.id }
        end
      end

      it 'redirects to cart' do
        get :new
        expect(response).to redirect_to(spree.cart_admin_order_path(Spree::Order.last))
      end
    end

    # Regression test for https://github.com/spree/spree/issues/3684
    # Rendering a form should under no circumstance mutate the order
    describe '#edit' do
      it 'does not refresh rates if the order is completed' do
        allow(order).to receive_messages completed?: true
        expect(order).not_to receive :refresh_shipment_rates
        get :edit, params: { id: order.number }
      end

      it 'does not refresh the rates if the order is incomplete' do
        allow(order).to receive_messages completed?: false
        expect(order).not_to receive :refresh_shipment_rates
        get :edit, params: { id: order.number }
      end

      context 'when order does not have a ship address' do
        before do
          allow(order).to receive_messages ship_address: nil
        end

        context 'when order_bill_address_used is true' do
          before { Spree::Config[:order_bill_address_used] = true }

          it 'redirects to the customer details page' do
            get :edit, params: { id: order.number }
            expect(response).to redirect_to(spree.edit_admin_order_customer_path(order))
          end
        end

        context 'when order_bill_address_used is false' do
          before { Spree::Config[:order_bill_address_used] = false }

          it 'redirects to the customer details page' do
            get :edit, params: { id: order.number }
            expect(response).to redirect_to(spree.edit_admin_order_customer_path(order))
          end
        end
      end
    end

    describe '#advance' do
      subject do
        put :advance, params: { id: order.number }
      end

      context 'when incomplete' do
        before do
          allow(order).to receive(:completed?).and_return(false, true)
          allow(order).to receive(:next).and_return(true, false)
        end

        context 'when successful' do
          before { allow(order).to receive(:can_complete?).and_return(true) }

          it 'messages and redirects' do
            subject
            expect(flash[:success]).to eq I18n.t('spree.order_ready_for_confirm')
            expect(response).to redirect_to(spree.confirm_admin_order_path(order))
          end
        end

        context 'when unsuccessful' do
          before do
            allow(order).to receive(:can_complete?).and_return(false)
            allow(order).to receive(:errors).and_return(double(full_messages: ['failed']))
          end

          it 'messages and redirects' do
            subject
            expect(flash[:error]).to eq order.errors.full_messages
            expect(response).to redirect_to(spree.confirm_admin_order_path(order))
          end
        end
      end

      context 'when already completed' do
        before { allow(order).to receive_messages completed?: true }

        it 'messages and redirects' do
          subject
          expect(flash[:notice]).to eq I18n.t('spree.order_already_completed')
          expect(response).to redirect_to(spree.edit_admin_order_path(order))
        end
      end
    end

    context '#confirm' do
      subject do
        get :confirm, params: { id: order.number }
      end

      context 'when in confirm' do
        before { allow(order).to receive_messages completed?: false, can_complete?: true }

        it 'renders the confirm page' do
          subject
          expect(response.status).to eq 200
          expect(response).to render_template(:confirm)
        end
      end

      context 'when before confirm' do
        before { allow(order).to receive_messages completed?: false, can_complete?: false }

        it 'renders the confirm_advance template (to allow refreshing of the order)' do
          subject
          expect(response.status).to eq 200
          expect(response).to render_template(:confirm_advance)
        end
      end

      context 'when already completed' do
        before { allow(order).to receive_messages completed?: true }

        it 'redirects to edit' do
          subject
          expect(response).to redirect_to(spree.edit_admin_order_path(order))
        end
      end
    end

    context "#complete" do
      subject do
        put :complete, params: { id: order.number }
      end

      context 'when successful' do
        before { allow(order).to receive(:complete!) }

        it 'completes the order' do
          expect(order).to receive(:complete!)
          subject
        end

        it 'messages and redirects' do
          subject
          expect(flash[:success]).to eq I18n.t('spree.order_completed')
          expect(response).to redirect_to(spree.edit_admin_order_path(order))
        end
      end

      context 'with an StateMachines::InvalidTransition error' do
        let(:order) { create(:order) }

        it 'messages and redirects' do
          subject
          expect(response).to redirect_to(spree.confirm_admin_order_path(order))
          expect(flash[:error].to_s).to include("Cannot transition state via :complete from :cart")
        end
      end

      context 'insufficient stock to complete the order' do
        before do
          expect(order).to receive(:complete!).and_raise Spree::Order::InsufficientStock
        end

        it 'messages and redirects' do
          subject
          expect(response).to redirect_to(spree.cart_admin_order_path(order))
          expect(flash[:error].to_s).to eq I18n.t('spree.insufficient_stock_for_order')
        end
      end
    end

    # Test for https://github.com/spree/spree/issues/3919
    context 'search' do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive_messages spree_current_user: user
        user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')

        create(:completed_order_with_totals)
        expect(Spree::Order.count).to eq 1
      end

      it 'does not display duplicate results' do
        get :index, params: { q: {
          line_items_variant_id_in: Spree::Order.first.variants.map(&:id)
        } }
        expect(assigns[:orders].map(&:number).count).to eq 1
      end
    end

    context '#not_finalized_adjustments' do
      let(:order) { create(:order) }
      let!(:finalized_adjustment) { create(:adjustment, finalized: true, adjustable: order, order: order) }

      it 'changes all the finalized adjustments to unfinalized' do
        post :unfinalize_adjustments, params: { id: order.number }
        expect(finalized_adjustment.reload.finalized).to eq(false)
      end

      it 'sets the flash success message' do
        post :unfinalize_adjustments, params: { id: order.number }
        expect(flash[:success]).to eql('All adjustments successfully unfinalized!')
      end

      context 'when referer' do
        before do
          request.env['HTTP_REFERER'] = '/'
        end

        it 'redirects back' do
          post :unfinalized_adjustments, params: { id: order.number }
          expect(response).to redirect_to('/')
        end
      end

      context 'when no referer' do
        before do
          request.env['HTTP_REFERER'] = nil
        end

        it 'refirects to fallback location' do
          post :unfinalized_adjustments, params : { id: order.number }
          expect(response).to redirect_to(spree.admin_order_adjustments_path(order))
        end
      end
    end

    context '#finalize_adjustments' do
      let(:order) { create(:order) }
      let!(:not_finalized_adjustment) { create(:adjustment, finalized: false, adjustable: order, order: order) }

      it 'changes all the unfinalized adjustments to finalized' do
        post :finalize_adjustments, params: { id: order.number }
        expect(not_finalized_adjustment.reload.finalized).to eq(true)
      end

      it 'sets the flash success message' do
        post :finalize_adjustments, params: { id: order.number }
        expect(flash[:success]).to eql('All adjustments successfully finalized!')
      end

      context 'when referer' do
        before do
          request.env['HTTP_REFERER'] = '/'
        end

        it 'redirects back' do
          post :finalize_adjustments, params: { id: order.number }
          expect(response).to redirect_to('/')
        end
      end

      context 'when no referer' do
        before do
          request.env['HTTP_REFERER'] = nil
        end

        it 'refirects to fallback location' do
          post :finalize_adjustments, params: { id: order.number }
          expect(response).to redirect_to(spree.admin_order_adjustments_path(order))
        end
      end
    end
  end

  context '#authorize_admin' do
    let(:user) { create(:user) }
    let(:order) { create(:completed_order_with_totals, number: 'R987654321') }

    before do
      allow(Spree::Order).to receive_messages find: order
      allow(controller).to receive_messages spree_current_user: user
    end

    it 'grants access to users with an admin role' do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      get :index
      expect(response).to render_template :index
    end

    it 'denies access to users without an admin role' do
      allow(user).to receive_messages has_spree_role?: false
      get :index
      expect(response).to redirect_to('/unauthorized')
    end

    it 'denies access to not signed in users' do
      allow(controller).to receive_messages spree_current_user: nil
      get :index
      expect(response).to redirect_to('/')
    end

    it 'restricts returned order(s) on index when using OrderSpecificAbility' do
      number = order.number

      create_list(:completed_order_with_totals, 3)
      expect(Spree::Order.complete.count).to eq 4

      with_ability(OrderSpecificAbility) do
        allow(user).to receive_messages has_spree_role?: false
        get :index
        expect(response).to render_template :index
        expect(assigns['orders'].size).to eq 1
        expect(assigns['orders'].first.number).to eq number        
      end
    end
  end

  context 'order number not given' do
    stub_authorization!

    it 'raise active record not found' do
      expect {
        get :edit, params: { id: 0 }
      }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
