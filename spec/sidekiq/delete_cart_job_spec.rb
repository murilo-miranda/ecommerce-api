require 'rails_helper'
RSpec.describe DeleteCartJob, type: :job do
  describe '.perform' do
    let(:cart) { Cart.create(total_price: 100, status: 'abandoned') }

    it 'marks carts as abandoned' do
      cart.update(updated_at: 7.days.ago)
      expect { DeleteCartJob.new.perform }.to change { Cart.count }.by(-1)
    end
  end
end
