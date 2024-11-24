class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform()
    active_carts = Cart.where('updated_at < ?', 3.hours.ago)
    active_carts.update_all(status: :abandoned)
  end
end
