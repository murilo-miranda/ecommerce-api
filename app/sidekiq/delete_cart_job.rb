class DeleteCartJob
  include Sidekiq::Job

  def perform()
    abandoned_carts = Cart.where('updated_at < ?', 7.days.ago)
    abandoned_carts.destroy_all
  end
end
