require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /cart" do
    subject do
      post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
    end

    context 'when cart does not exist' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let(:expected_response) do
        {
          id: Cart.last.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 1,
              unit_price: product.price,
              total_price: product.price
            }
          ],
          total_price: product.price
        }.to_json
      end

      it 'creates a new cart' do
        expect { subject }.to change { Cart.count }.by(1)
      end

      it 'returns status code 201 with cart data' do
        subject
        expect(response).to have_http_status(:created)
        expect(response.body).to eq(expected_response)
      end
    end

    context 'when cart exists but is abandoned less than 2 hours' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let!(:cart) { Cart.create(total_price: 0) }
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
            }
          ],
          total_price: product.price
        }.to_json
      end

      before do
        cart.update(updated_at: 2.hours.ago)
      end

      it 'does not create a new cart' do
        expect { subject }.not_to change { Cart.count }
      end

      it 'returns status code 201 with cart data' do
        subject
        expect(response).to have_http_status(:created)
        expect(response.body).to eq(expected_response)
      end
    end
    
    context 'when cart exists but is abandoned more than 3 hours' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let!(:cart) { Cart.create(total_price: 0) }
      let(:expected_response) do
        {
          id: Cart.last.id,
          products: [
            {
              id: product.id,
              name: product.name,
              quantity: 1,
              unit_price: product.price,
              total_price: product.price
            }
          ],
          total_price: product.price
        }.to_json
      end

      before do
        cart.update(updated_at: 4.hours.ago)
        cart.mark_as_abandoned
      end

      it 'creates a new cart' do
        expect { subject }.to change { Cart.count }.by(1)
        expect(Cart.last.status).to eq('active')
      end

      it 'returns status code 201 with cart data' do
        subject
        expect(response).to have_http_status(:created)
        expect(response.body).to eq(expected_response)
      end
    end
  end
  
  describe "GET /cart" do
    subject do
      get '/cart'
    end
    
    context 'when cart exists' do
      let(:cart) { Cart.create(total_price: 0) }
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let(:product2) { Product.create(name: "Test Product 2", price: 3.60) }
      let(:product3) { Product.create(name: "Test Product 3", price: 24.50) }
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
              id: product2.id,
              name: product2.name,
              quantity: 1,
              unit_price: product2.price,
              total_price: product2.price
            },
            {
              id: product3.id,
              name: product3.name,
              quantity: 1,
              unit_price: product3.price,
              total_price: product3.price
            }
          ],
          total_price: product.price + product2.price + product3.price
        }
      end
      
      it 'returns status code 200 and the cart' do
        CartItem.create(cart: cart, product: product, quantity: 1)
        CartItem.create(cart: cart, product: product2, quantity: 1)
        CartItem.create(cart: cart, product: product3, quantity: 1)
        
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected_response.to_json)
      end
    end

    context 'when cart does not exist' do
      it 'returns status code 404' do
        subject
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq({ error: 'Cart not found. Please create a new cart' }.to_json)
      end
    end
  end
  
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
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
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
        post '/cart/add_item', params: { product_id: new_product.id, quantity: 2 }, as: :json
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

    context 'when fail due to invalid quantity param' do
      let(:expected_response) do
        {
          quantity: ["must be greater than or equal to 1"]
        }.to_json
      end
      
      subject do
        post '/cart/add_item', params: { product_id: new_product.id, quantity: -1 }, as: :json
      end

      it 'does not add a new item in the cart' do
        expect { subject }.not_to change { CartItem.count }
      end

      it 'returns cart item errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq(expected_response)
      end
    end
  end

  describe "DELETE /cart/:product_id" do
    context 'when cart does not exist' do
      it 'returns status code 404' do
        delete '/cart/1'
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq({ error: 'Cart not found. Please create a new cart' }.to_json)
      end
    end

    context 'when there is more than one product in the cart' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let(:product2) { Product.create(name: "Test Product 2", price: 3.60) }
      let(:cart) { Cart.create(total_price: 0) }
      let(:expected_response) do
        {
          id: cart.id,
          products: [
            {
              id: product2.id,
              name: product2.name,
              quantity: 1,
              unit_price: product2.price,
              total_price: product2.price
            }
          ],
          total_price: product2.price
        }.to_json
      end

      subject do
        delete "/cart/#{product.id}"
      end

      it 'removes the product from the cart' do
        CartItem.create(cart: cart, product: product, quantity: 1)
        CartItem.create(cart: cart, product: product2, quantity: 1)

        expect { subject }.to change { CartItem.count }.by(-1)
      end

      it 'returns the updated cart' do
        CartItem.create(cart: cart, product: product, quantity: 1)
        CartItem.create(cart: cart, product: product2, quantity: 1)
        
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected_response)
      end
    end

    context 'when product does not exist' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let(:product2) { Product.create(name: "Test Product 2", price: 3.60) }
      let(:cart) { Cart.create(total_price: 0) }

      subject do
        delete "/cart/#{product.id}"
      end

      it 'does not remove the product from the cart' do
        CartItem.create(cart: cart, product: product2, quantity: 1)
        
        expect { subject }.not_to change { CartItem.count }
      end

      it 'returns status code 404' do
        CartItem.create(cart: cart, product: product2, quantity: 1)
        
        subject
        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq({ error: 'Product not found in cart' }.to_json)
      end
    end

    context 'when there is only one product in the cart' do
      let(:product) { Product.create(name: "Test Product", price: 10.0) }
      let(:cart) { Cart.create(total_price: 0) }

      subject do
        delete "/cart/#{product.id}"
      end

      it 'removes the product from the cart' do
        CartItem.create(cart: cart, product: product, quantity: 1)
        
        expect { subject }.to change { CartItem.count }.by(-1)
      end

      it 'returns status code 200 and a message' do
        CartItem.create(cart: cart, product: product, quantity: 1)
        
        subject
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({ message: 'Cart is empty' }.to_json)
      end
    end
  end
end
