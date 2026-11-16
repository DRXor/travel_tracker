require "test_helper"

class TripBudgetTest < ActiveSupport::TestCase
  setup do
    @anna  = User.create!(name: "Анна", email: "anna_budget@example.com", password: "password123")
    @boris = User.create!(name: "Борис", email: "boris_budget@example.com", password: "password123")
    @trip = Trip.create!(user: @anna, name: "Отпуск", budget: 1000,
                         start_date: Date.current + 5, end_date: Date.current + 9)
    @trip.trip_memberships.create!(user: @boris)
    @trip.reload
  end

  # --- контекст: итоги и остаток ---

  test "total_spent и remaining_budget считают сумму расходов" do
    add_expense(@anna, 300)
    add_expense(@boris, 200)

    assert_equal 500, @trip.total_spent
    assert_equal 500, @trip.remaining_budget
    assert_not @trip.over_budget?
  end

  test "over_budget? истинно при превышении, полоска не больше 100 процентов" do
    add_expense(@anna, 1200)

    assert @trip.over_budget?
    assert_equal(-200, @trip.remaining_budget)
    assert_equal 100, @trip.budget_used_percent
  end

  test "без бюджета нет остатка и превышения" do
    @trip.update!(budget: nil)
    add_expense(@anna, 300)

    assert_nil @trip.remaining_budget
    assert_not @trip.over_budget?
    assert_equal 0, @trip.budget_used_percent
  end

  test "budget_used_percent считает долю потраченного" do
    add_expense(@anna, 250)
    assert_equal 25, @trip.budget_used_percent
  end

  # --- контекст: категории ---

  test "spent_by_category группирует расходы по категориям" do
    add_expense(@anna, 100, category: :food)
    add_expense(@boris, 50, category: :food)
    add_expense(@anna, 400, category: :lodging)

    assert_equal({ "food" => 150, "lodging" => 400 }, @trip.spent_by_category)
  end

  # --- контекст: баланс участников ---

  test "balances: кто заплатил больше доли, тому должны" do
    add_expense(@anna, 600)

    balances = @trip.balances
    assert_equal 300, balances[@anna]
    assert_equal(-300, balances[@boris])
  end

  test "balances: при равных тратах все в расчёте" do
    add_expense(@anna, 200)
    add_expense(@boris, 200)

    assert_equal [0, 0], @trip.balances.values
  end

  test "balances без расходов нулевые" do
    assert_equal [0, 0], @trip.balances.values
  end

  private

  def add_expense(user, amount, category: :other)
    Expense.create!(trip: @trip, user: user, title: "Трата", amount: amount,
                    category: category, spent_on: Date.current)
  end
end