class CartsController < ApplicationController
  before_action :set_cart, only: %i[ show destroy ]

  def create
    cart = Cart.last || Cart.create(total_price: 0)
    cart = Cart.create(total_price: 0) if cart.abandoned?

    CartItem.create(cart_id: cart.id, product_id: cart_params[:product_id], quantity: cart_params[:quantity])

    render json: json_response(cart.reload), status: :created
  end
  
  def show
    render json: json_response(@cart), status: :ok
  end
  
  def add_item
    cart = Cart.last

    product = Product.find(cart_params[:product_id])

    cart_item = CartItem.find_or_initialize_by(cart: cart, product: product)
    
    begin
      update_cart(cart, cart_item)
      render json: json_response(cart), status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: cart_item.errors, status: :unprocessable_entity
    end
  end

  def destroy
    cart_item = CartItem.find_by(cart: @cart, product: product_id)

    if cart_item
      cart_item.destroy

      if @cart.cart_items.exists?
        render json: json_response(@cart.reload), status: :ok
      else
        render json: { message: 'Cart is empty' }, status: :ok
      end
    else
      render json: { error: 'Product not found in cart' }, status: :not_found
    end
  end

  private

  def product_id
    params.permit(:product_id)[:product_id]
  end
  
  def cart_params
    params.permit(:product_id, :quantity)
  end

  def update_cart(cart, cart_item)
    CartItem.transaction do
      cart_item.update!(quantity: cart_item.quantity += cart_params[:quantity].to_i)
    end
  end

  def set_cart
    @cart = Cart.last!
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Cart not found. Please create a new cart' }, status: :not_found
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
