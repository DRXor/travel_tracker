require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  setup do
    user = User.create!(name: "Тест", email: "item_test@example.com", password: "password123")
    trip = Trip.create!(user: user, name: "Рим",
                        start_date: Date.current + 10, end_date: Date.current + 13)
    @item = trip.checklist_items.create!(title: "Билеты")
  end

  # --- контекст: toggle_done! ---

  test "по умолчанию пункт не выполнен" do
    assert_not @item.done?
  end

  test "toggle_done! отмечает пункт выполненным" do
    @item.toggle_done!
    assert @item.reload.done?
  end

  test "повторный toggle_done! снимает отметку" do
    2.times { @item.toggle_done! }
    assert_not @item.reload.done?
  end

  # --- валидации (опционально) ---

  test "название пункта обязательно" do
    @item.title = ""
    assert_not @item.valid?
  end
end