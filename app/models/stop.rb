class Stop < ApplicationRecord
  belongs_to :trip

  validates :name, presence: true, length: { maximum: 120 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :coordinates_come_in_pairs

  before_validation :assign_position, on: :create
  after_destroy :close_position_gap

  # Есть ли у остановки точка на карте
  def located?
    latitude.present? && longitude.present?
  end

  private

  def coordinates_come_in_pairs
    return if latitude.present? == longitude.present?
    errors.add(:base, "Укажи обе координаты: широту и долготу")
  end

  # Новая остановка встаёт в конец маршрута
  def assign_position
    return unless trip
    self.position ||= (trip.stops.maximum(:position) || 0) + 1
  end

  # Закрываем «дырку» в нумерации одним UPDATE: все остановки правее
  # удалённой сдвигаются на единицу влево.
  def close_position_gap
    return if destroyed_by_association

    Stop.where(trip_id: trip_id)
        .where("position > ?", position)
        .update_all("position = position - 1")
  end
end