class Expense < ApplicationRecord
  CATEGORY_LABELS = {
    "transport"     => "Транспорт",
    "lodging"       => "Жильё",
    "food"          => "Еда",
    "entertainment" => "Развлечения",
    "other"         => "Другое"
  }.freeze

  belongs_to :trip
  belongs_to :user

  enum :category, { transport: 0, lodging: 1, food: 2, entertainment: 3, other: 4 }, validate: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :amount, numericality: { greater_than: 0, less_than: 100_000_000 }
  validates :spent_on, presence: true
  validate :payer_is_participant

  after_create_commit :broadcast_created
  after_destroy_commit :broadcast_removed

  def category_label
    CATEGORY_LABELS.fetch(category)
  end

  private

  def payer_is_participant
    errors.add(:user, "не участвует в этой поездке") unless trip&.participant?(user)
  end

  def broadcast_created
    broadcast_prepend_to trip, target: "expenses"
    broadcast_summary
  end

  def broadcast_removed
    return if destroyed_by_association
    broadcast_remove_to trip
    broadcast_summary
  end

  # Итоги бюджета обновляются у всех участников
  def broadcast_summary
    broadcast_replace_to trip, target: "budget_summary",
                         partial: "trips/budget_summary", locals: { trip: trip }
  end
end