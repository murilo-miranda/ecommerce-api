class CartItem < ApplicationRecord
  after_save :update_cart_total_price  
  validates_numericality_of :quantity, greater_than_or_equal_to: 1

  belongs_to :cart
  belongs_to :product

  private

  def update_cart_total_price
    cart.update(total_price: cart.total_price + (quantity * product.price))
  end
end
