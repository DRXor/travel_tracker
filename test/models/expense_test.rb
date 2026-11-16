require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @anna = User.create!(name: "Анна", email: "anna_expense@example.com", password: "password123")
    @stranger = User.create!(name: "Вера", email: "vera_expense@example.com", password: "password123")
    @trip = Trip.create!(user: @anna, name: "Отпуск",
                         start_date: Date.current + 5, end_date: Date.current + 9)
  end

  # --- контекст: валидации ---

  test "сумма должна быть больше нуля" do
    assert_not build_expense(amount: 0).valid?
    assert_not build_expense(amount: -10).valid?
    assert build_expense(amount: 10.5).valid?
  end

  test "название обязательно" do
    assert_not build_expense(title: "").valid?
  end

  test "неизвестная категория недопустима" do
    assert_not build_expense(category: "космос").valid?
  end

  # --- контекст: кто может платить ---

  test "расход может записать только участник поездки" do
    assert build_expense(user: @anna).valid?
    assert_not build_expense(user: @stranger).valid?

    @trip.trip_memberships.create!(user: @stranger)
    assert build_expense(user: @stranger).valid?
  end

  test "category_label даёт русское название" do
    assert_equal "Еда", build_expense(category: :food).category_label
  end

  private

  def build_expense(**attrs)
    Expense.new({ trip: @trip, user: @anna, title: "Билеты", amount: 100,
                  category: :transport, spent_on: Date.current }.merge(attrs))
  end
end
