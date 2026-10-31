class Stop < ApplicationRecord
  belongs_to :trip

  validates :name, presence: true, length: { maximum: 120 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  before_validation :assign_position, on: :create
  after_destroy :renumber_siblings

  private

  # Новая остановка встаёт в конец маршрута
  def assign_position
    return unless trip
    self.position ||= (trip.stops.maximum(:position) || 0) + 1
  end

  # После удаления номера идут без дырок: 1, 2, 3
  def renumber_siblings
    return if destroyed_by_association
    trip.stops.reload.each.with_index(1) do |stop, index|
      stop.update_column(:position, index) unless stop.position == index
    end
  end
end