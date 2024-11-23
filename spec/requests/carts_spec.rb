require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /add_items" do
    let(:cart) { Cart.create(total_price: 0) }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let(:new_product) { Product.create(name: "New Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      let(:expected_response) do  
        {
          id: cart.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 3,
              unit_price: product.price,
              total_price: product.price * 3
            }
          ],
          total_price: product.price * 3
        }.to_json
      end
      
      subject do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end

      it 'returns the updated cart' do
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected_response)
      end
    end

    context 'when is a new product' do
      let(:expected_response) do  
        {
          id: cart.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 1,
              unit_price: product.price,
              total_price: product.price
            },
            {
              id: new_product.id,
              name: new_product.name,
              quantity: 2,
              unit_price: new_product.price,
              total_price: new_product.price * 2
            }
          ],
          total_price: product.price + ( new_product.price * 2 )
        }.to_json
      end
      
      subject do
        post '/cart/add_items', params: { product_id: new_product.id, quantity: 2 }, as: :json
      end

      it 'add a new item in the cart' do
        expect { subject }.to change { CartItem.count }.by(1)
      end

      it 'returns the updated cart' do
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected_response)
      end
    end
  end
end
