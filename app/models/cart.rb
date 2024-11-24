class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  has_many :cart_items
  has_many :products, through: :cart_items

  enum status: { active: 0, abandoned: 1 }

  def mark_as_abandoned
    abandoned! if updated_at < 3.hours.ago
  end

  def remove_if_abandoned 
    destroy if (updated_at < 7.days.ago && abandoned?)
  end
end
