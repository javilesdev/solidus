require 'spec_helper'

class FakesController < ApplicationController
  include Spree::Core::ControllerHelpers::Order
end

describe Spree::Core::ControllerHelpers::Order, type: :controller do
  controller(FakesController) {}

  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, store: store) }
  let(:store) { create(:store) }

  before do
    allow(controller).to receive_messages(current_store: store)
    allow(controller).to receive_messages(current_pricing_options: Spree::Config.pricing_options_class.new(currency: Spree::Config.currency))
    allow(controller).to receive_messages(try_spree_current_user: user)
  end

  describe '#simple_current_order' do
    it "returns an empty order" do
      expect(controller.simple_current_order.item_count).to eq 0
    end
    it 'returns Spree::Order instance' do
      allow(controller).to receive_messages(cookies: double(signed: { guest_token: order.guest_token }))
      expect(controller.simple_current_order).to eq order
    end
  end

  describe '#current_order' do
    context 'create_order_if_necessary option is false' do
      let!(:order) { create :order, user: user, store: store }
      it 'returns current order' do
        expect(controller.current_order).to eq order
      end
    end
    context 'create_order_if_necessary option is true' do
      it 'creates new order' do
        expect {
          controller.current_order(create_order_if_necessary: true)
        }.to change(Spree::Order, :count).to(1)
      end

      it 'assigns the current_store id' do
        controller.current_order(create_order_if_necessary: true)
        expect(Spree::Order.last.store_id).to eq store.id
      end
    end
  end

  describe '#associate_user' do
    before { allow(controller).to receive_messages(current_order: order) }
    context "user's email is blank" do
      let(:user) { create(:user, email: '') }
      it 'calls Spree::Order#associate_user! method' do
        expect_any_instance_of(Spree::Order).to receive(:associate_user!)
        controller.associate_user
      end
    end
    context "user isn't blank" do
      it 'does not calls Spree::Order#associate_user! method' do
        expect_any_instance_of(Spree::Order).not_to receive(:associate_user!)
        controller.associate_user
      end
    end
  end

  describe '#set_current_order' do
    let(:incomplete_order) { create(:order, user: user) }

    context 'when current order not equal to users incomplete orders' do
      before { allow(controller).to receive_messages(current_order: order, last_incomplete_order: incomplete_order, cookies: double(signed: { guest_token: 'guest_token' })) }

      it 'calls Spree::Order#merge! method' do
        expect(order).to receive(:merge!).with(incomplete_order, user)
        controller.set_current_order
      end
    end
  end

  describe '#ip_address' do
    it 'returns remote ip' do
      expect(controller.ip_address).to eq request.remote_ip
    end
  end
end
