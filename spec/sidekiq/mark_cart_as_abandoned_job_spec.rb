require 'rails_helper'
RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '.perform' do
    let(:cart) { Cart.create(total_price: 100) }

    it 'marks carts as abandoned' do
      cart.update(updated_at: 4.hours.ago)
      expect { MarkCartAsAbandonedJob.new.perform }.to change { cart.reload.status }.from('active').to('abandoned')
    end
  end
end
