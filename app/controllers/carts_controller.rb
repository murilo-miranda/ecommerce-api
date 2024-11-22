class CartsController < ApplicationController
  ## TODO Escreva a lógica dos carrinhos aqui
  def add_items
    cart = Cart.last

    product = Product.find(cart_params[:product_id])

    cart_item = CartItem.find_or_initialize_by(cart: cart, product: product)

    cart_item.quantity += cart_params[:quantity].to_i

    if @cart_item.save
      render json: @cart_item, status: :created, location: @cart_item
    else
      render json: @cart_item.errors, status: :unprocessable_entity
    end
  end

  private

  def cart_params
    params.permit(:product_id, :quantity)
  end
end
