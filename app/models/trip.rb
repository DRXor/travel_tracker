class Trip < ApplicationRecord
  SOON_DAYS = 14
  EARTH_RADIUS_KM = 6371.0

  belongs_to :user
  has_many :stops, -> { order(:position) }, dependent: :destroy
  has_many :checklist_items, dependent: :destroy
  has_many :trip_memberships, dependent: :destroy
  has_many :members, through: :trip_memberships, source: :user
  has_many :expenses, -> { order(spent_on: :desc, id: :desc) }, dependent: :destroy
  has_many :comments, -> { order(:created_at) }, dependent: :destroy

  enum :status, { draft: 0, planned: 1, completed: 2, cancelled: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :start_date, :end_date, presence: true
  validates :budget, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :end_date_not_before_start_date

  # Сколько дней длится поездка (включая первый и последний)
  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  # Метка «Скоро»: запланирована и стартует в ближайшие 14 дней
  def soon?
    planned? && start_date.between?(Date.current, Date.current + SOON_DAYS)
  end

  # Готовность в процентах по пунктам подготовки
  def progress_percent
    total = checklist_items.count
    return 0 if total.zero?
    (checklist_items.where(done: true).count * 100.0 / total).round
  end

  def complete
    return false unless planned?
    update(status: :completed)
  end

  def cancel
    return false if completed? || cancelled?
    update(status: :cancelled)
  end

  def plan
    return false unless draft?
    update(status: :planned)
  end

  # «Её можно вернуть в черновики» из карточки отменённой поездки
  def restore_to_draft
    return false unless cancelled?
    update(status: :draft)
  end

  # Остановки, у которых есть точка на карте (по порядку маршрута)
  def located_stops
    stops.select(&:located?)
  end

  # Длина маршрута по прямым между точками, в километрах
  def route_distance_km
    points = located_stops
    return 0.0 if points.size < 2
    points.each_cons(2).sum { |a, b| haversine_km(a, b) }.round(1)
  end

    # --- участники ---

  def owner?(person)
    person.present? && user_id == person.id
  end

  def participant?(person)
    return false if person.blank?
    owner?(person) || trip_memberships.exists?(user_id: person.id)
  end

  def participants
    [user, *members]
  end

  # --- бюджет ---

  def total_spent
    expense_scope.sum(:amount)
  end

  def remaining_budget
    budget && budget - total_spent
  end

  def over_budget?
    budget.present? && total_spent > budget
  end

  # Процент для полоски (не больше 100)
  def budget_used_percent
    return 0 if budget.blank? || budget.zero?
    [(total_spent * 100 / budget).round, 100].min
  end

  def spent_by_category
    expense_scope.group(:category).sum(:amount)
  end

  # Баланс каждого участника: плюс — ему должны, минус — он должен.
  # Суммы берутся одним запросом на всех, без запросов в цикле.
  def balances
    paid = expense_scope.group(:user_id).sum(:amount)
    people = participants
    share = paid.values.sum / people.size
    people.to_h { |person| [person, (paid.fetch(person.id, 0) - share).round(2)] }
  end

  private

  def end_date_not_before_start_date
    return unless start_date && end_date
    errors.add(:end_date, "не может быть раньше даты начала") if end_date < start_date
  end

  def haversine_km(a, b)
    rad = Math::PI / 180
    dlat = (b.latitude - a.latitude).to_f * rad
    dlon = (b.longitude - a.longitude).to_f * rad
    h = Math.sin(dlat / 2)**2 +
        Math.cos(a.latitude.to_f * rad) * Math.cos(b.latitude.to_f * rad) * Math.sin(dlon / 2)**2
    2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(h))
  end

    # Агрегаты считаем по таблице напрямую: у ассоциации есть сортировка, она мешает группировке
  def expense_scope
    Expense.where(trip_id: id)
  end
end
