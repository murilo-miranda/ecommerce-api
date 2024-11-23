class CartsController < ApplicationController
  def add_items
    cart = Cart.last

    product = Product.find(cart_params[:product_id])

    cart_item = CartItem.find_or_initialize_by(cart: cart, product: product)
    
    Cart.transaction do
      update_cart(cart, cart_item)
      render json: json_response(cart), status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: cart_item.errors, status: :unprocessable_entity
    end
  end

  private

  def cart_params
    params.permit(:product_id, :quantity)
  end

  def update_cart(cart, cart_item)
    cart_item.update!(quantity: cart_item.quantity += cart_params[:quantity].to_i)
    cart.update!(total_price: cart.cart_items.sum {|cart_item| cart_item.quantity * cart_item.product.price })
  end

  def json_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.includes(:product).map do |cart_item|
        {
          id: cart_item.product.id,
          name: cart_item.product.name,
          quantity: cart_item.quantity,
          unit_price: cart_item.product.price,
          total_price: cart_item.product.price * cart_item.quantity
        }
      end,
      total_price: cart.total_price
    }
  end
end
