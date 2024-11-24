require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'mark_as_abandoned' do
    let(:cart) { Cart.create(total_price: 0) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      cart.update(updated_at: 3.hours.ago)
      expect { cart.mark_as_abandoned }.to change { cart.abandoned? }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:cart) { Cart.create(total_price: 0, status: 'abandoned') }
    
    it 'removes the shopping cart if abandoned for a certain time' do
      cart.update(updated_at: 7.days.ago)
      expect { cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end
  end
end
