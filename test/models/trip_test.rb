require "test_helper"

class TripTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Тест", email: "trip_test@example.com", password: "password123")
    @trip = Trip.create!(
      user: @user, name: "Париж", status: :planned,
      start_date: Date.current + 30, end_date: Date.current + 34
    )
  end

  # --- контекст: duration_days ---

  test "duration_days считает дни включительно" do
    assert_equal 5, @trip.duration_days
  end

  test "duration_days для поездки в один день равно 1" do
    @trip.end_date = @trip.start_date
    assert_equal 1, @trip.duration_days
  end

  # --- контекст: soon? ---

  test "soon? истинно для запланированной поездки через 5 дней" do
    @trip.start_date = Date.current + 5
    assert @trip.soon?
  end

  test "soon? ложно, если до поездки больше 14 дней" do
    assert_not @trip.soon?
  end

  test "soon? ложно для черновика" do
    @trip.update!(status: :draft, start_date: Date.current + 5, end_date: Date.current + 7)
    assert_not @trip.soon?
  end

  # --- контекст: progress_percent ---

  test "progress_percent равно 0 без пунктов" do
    assert_equal 0, @trip.progress_percent
  end

  test "progress_percent: 3 из 5 пунктов это 60 процентов" do
    5.times { |i| @trip.checklist_items.create!(title: "Пункт #{i}", done: i < 3) }
    assert_equal 60, @trip.progress_percent
  end

  # --- контекст: смена статуса ---

  test "complete завершает запланированную поездку" do
    assert @trip.complete
    assert @trip.completed?
  end

  test "complete не работает для черновика" do
    @trip.update!(status: :draft)
    assert_not @trip.complete
    assert @trip.draft?
  end

  test "cancel отменяет поездку, а завершённую не трогает" do
    assert @trip.cancel
    assert @trip.cancelled?

    done_trip = Trip.create!(user: @user, name: "Рим", status: :completed,
                             start_date: Date.current - 10, end_date: Date.current - 8)
    assert_not done_trip.cancel
    assert done_trip.completed?
  end

  test "restore_to_draft возвращает отменённую поездку в черновики" do
    @trip.cancel
    assert @trip.restore_to_draft
    assert @trip.draft?
  end

  # --- валидации (опционально) ---

  test "дата окончания не может быть раньше даты начала" do
    @trip.end_date = @trip.start_date - 1
    assert_not @trip.valid?
    assert_includes @trip.errors[:end_date], "не может быть раньше даты начала"
  end

  test "название обязательно" do
    @trip.name = ""
    assert_not @trip.valid?
  end
end