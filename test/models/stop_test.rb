require "test_helper"

class StopTest < ActiveSupport::TestCase
  setup do
    user = User.create!(name: "Тест", email: "stop_test@example.com", password: "password123")
    @trip = Trip.create!(user: user, name: "Токио",
                         start_date: Date.current + 10, end_date: Date.current + 15)
  end

  # --- контекст: автоматический номер ---

  test "первая остановка получает номер 1" do
    stop = @trip.stops.create!(name: "Эйфелева башня")
    assert_equal 1, stop.position
  end

  test "следующие остановки нумеруются по порядку" do
    @trip.stops.create!(name: "А")
    @trip.stops.create!(name: "Б")
    third = @trip.stops.create!(name: "В")
    assert_equal 3, third.position
  end

  # --- контекст: удаление ---

  test "после удаления остановки номера идут без пропусков" do
    first  = @trip.stops.create!(name: "А")
    second = @trip.stops.create!(name: "Б")
    third  = @trip.stops.create!(name: "В")

    second.destroy

    assert_equal [1, 2], @trip.stops.reload.map(&:position)
    assert_equal "В", @trip.stops.last.name
    assert_equal 1, first.reload.position
  end

  test "при удалении поездки удаляются её остановки" do
    @trip.stops.create!(name: "А")
    assert_difference("Stop.count", -1) { @trip.destroy }
  end

  # --- валидации (опционально) ---

  test "название остановки обязательно" do
    assert_not @trip.stops.build(name: "").valid?
  end

    # --- контекст: перенумерация одним запросом ---

  test "после удаления первой остановки остальные сдвигаются на 1" do
    stops = %w[А Б В Г].map { |name| @trip.stops.create!(name: name) }
    stops.first.destroy

    assert_equal %w[Б В Г], @trip.stops.reload.map(&:name)
    assert_equal [1, 2, 3], @trip.stops.map(&:position)
  end

  test "удаление последней остановки не меняет остальные" do
    stops = %w[А Б В].map { |name| @trip.stops.create!(name: name) }
    stops.last.destroy

    assert_equal [1, 2], @trip.stops.reload.map(&:position)
  end

  test "перенумерация делает ровно один UPDATE независимо от числа остановок" do
    stops = 10.times.map { |i| @trip.stops.create!(name: "Точка #{i}") }

    updates = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      updates << payload[:sql] if payload[:sql].start_with?("UPDATE")
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      stops.first.destroy
    end

    assert_equal 1, updates.size
  end
end