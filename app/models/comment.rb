class Comment < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  validates :body, presence: true, length: { maximum: 500 }

  # Рассылка подписчикам страницы поездки по WebSocket
  after_create_commit :broadcast_created
  after_update_commit -> { broadcast_replace_to trip }
  after_destroy_commit :broadcast_removed

  private

  def broadcast_created
    broadcast_append_to trip, target: "comments"
    broadcast_header
  end

  def broadcast_removed
    return if destroyed_by_association # поездку удаляют целиком, рассылать нечего
    broadcast_remove_to trip
    broadcast_header
  end

  # Заголовок «Комментарии (N)» обновляется у всех
  def broadcast_header
    broadcast_replace_to trip, target: "comments_header",
                         partial: "comments/header", locals: { trip: trip }
  end
end