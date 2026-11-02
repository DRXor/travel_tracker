module TripsHelper
  STATUS_BADGES = {
    "draft"     => ["Черновик", ""],
    "planned"   => ["Запланировано", "badge--primary"],
    "completed" => ["Завершено", "badge--success"],
    "cancelled" => ["Отменено", "badge--danger"]
  }.freeze

  def trip_status_badge(trip)
    label, css = STATUS_BADGES.fetch(trip.status)
    content_tag(:span, label, class: "badge #{css}".strip)
  end
end