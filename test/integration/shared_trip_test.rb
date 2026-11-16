require "test_helper"

class SharedTripTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @owner    = User.create!(name: "Анна", email: "owner@example.com", password: "password123")
    @member   = User.create!(name: "Борис", email: "member@example.com", password: "password123")
    @outsider = User.create!(name: "Вера", email: "outsider@example.com", password: "password123")
    @trip = Trip.create!(user: @owner, name: "Семейный отпуск", budget: 1000,
                         start_date: Date.current + 10, end_date: Date.current + 15)
  end

  # --- контекст: приглашение участников ---

  test "владелец добавляет участника по email, и тот видит поездку" do
    sign_in(@owner)
    assert_difference("TripMembership.count", 1) do
      post trip_memberships_path(@trip), params: { email: "member@example.com" }
    end
    assert_redirected_to trip_path(@trip)

    sign_in(@member)
    get trips_path
    assert_select "h2 a", "Семейный отпуск"
    get trip_path(@trip)
    assert_response :success
  end

  test "email незарегистрированного пользователя не добавляется" do
    sign_in(@owner)
    assert_no_difference("TripMembership.count") do
      post trip_memberships_path(@trip), params: { email: "nobody@example.com" }
    end
    assert_match "не найден", flash[:alert]
  end

  # --- ответвление: права ---

  test "посторонний не видит чужую поездку и не добавляет расходы" do
    sign_in(@outsider)

    get trip_path(@trip)
    assert_response :not_found

    assert_no_difference("Expense.count") do
      post trip_expenses_path(@trip), params: { expense: { title: "Х", amount: 10, category: "food", spent_on: Date.current } }
    end
    assert_response :not_found
  end

  test "участник не может удалять поездку, менять статус и приглашать других" do
    @trip.trip_memberships.create!(user: @member)
    sign_in(@member)

    assert_no_difference("Trip.count") { delete trip_path(@trip) }
    assert_response :not_found

    patch complete_trip_path(@trip)
    assert_response :not_found

    assert_no_difference("TripMembership.count") do
      post trip_memberships_path(@trip), params: { email: "outsider@example.com" }
    end
    assert_response :not_found
  end

  test "участник может выйти из поездки, но не может убрать другого участника" do
    @trip.trip_memberships.create!(user: @member)
    other = @trip.trip_memberships.create!(user: @outsider)
    sign_in(@member)

    delete trip_membership_path(@trip, other)
    assert_response :forbidden

    mine = @trip.trip_memberships.find_by(user: @member)
    assert_difference("TripMembership.count", -1) { delete trip_membership_path(@trip, mine) }
    assert_redirected_to trips_path
  end

  # --- контекст: расходы и живое обновление ---

  test "участник добавляет расход, и рассылка уходит всем подписчикам" do
    @trip.trip_memberships.create!(user: @member)
    sign_in(@member)

    assert_turbo_stream_broadcasts @trip do
      assert_difference("Expense.count", 1) do
        post trip_expenses_path(@trip),
             params: { expense: { title: "Билеты", amount: "450.50", category: "transport", spent_on: Date.current } },
             headers: TURBO
      end
    end
    assert_response :success
    assert_equal @member, Expense.last.user

    get trip_path(@trip)
    assert_match "450,50", response.body
  end

  test "расход с отрицательной суммой не создаётся" do
    sign_in(@owner)
    assert_no_difference("Expense.count") do
      post trip_expenses_path(@trip),
           params: { expense: { title: "Ошибка", amount: "-5", category: "food", spent_on: Date.current } },
           headers: TURBO
    end
    assert_response :unprocessable_entity
  end

  test "участник удаляет только свои расходы, а владелец любые" do
    @trip.trip_memberships.create!(user: @member)
    owners = Expense.create!(trip: @trip, user: @owner, title: "Отель", amount: 700,
                             category: :lodging, spent_on: Date.current)
    mine = Expense.create!(trip: @trip, user: @member, title: "Кафе", amount: 50,
                           category: :food, spent_on: Date.current)

    sign_in(@member)
    assert_no_difference("Expense.count") { delete trip_expense_path(@trip, owners) }
    assert_response :not_found
    assert_difference("Expense.count", -1) { delete trip_expense_path(@trip, mine) }

    again = Expense.create!(trip: @trip, user: @member, title: "Такси", amount: 30,
                            category: :transport, spent_on: Date.current)
    sign_in(@owner)
    assert_difference("Expense.count", -1) { delete trip_expense_path(@trip, again) }
  end
end