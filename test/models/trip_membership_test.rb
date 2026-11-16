require "test_helper"

class TripMembershipTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(name: "Анна", email: "owner_m@example.com", password: "password123")
    @guest = User.create!(name: "Борис", email: "guest_m@example.com", password: "password123")
    @trip = Trip.create!(user: @owner, name: "Отпуск",
                         start_date: Date.current + 5, end_date: Date.current + 9)
  end

  # --- контекст: валидации ---

  test "владельца нельзя добавить участником" do
    assert_not @trip.trip_memberships.build(user: @owner).valid?
  end

  test "один пользователь не может быть добавлен дважды" do
    @trip.trip_memberships.create!(user: @guest)
    assert_not @trip.trip_memberships.build(user: @guest).valid?
  end

  # --- контекст: доступ ---

  test "participant? и accessible_trips учитывают владельца и участников" do
    assert @trip.participant?(@owner)
    assert_not @trip.participant?(@guest)
    assert_not_includes @guest.accessible_trips, @trip

    @trip.trip_memberships.create!(user: @guest)

    assert @trip.participant?(@guest)
    assert_includes @guest.accessible_trips, @trip
    assert_includes @owner.accessible_trips, @trip
  end
end
