require "test_helper"

class TripFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Анна", email: "anna@example.com", password: "password123")
    sign_in(@user)
  end

  # --- контекст: основной сценарий (happy path) ---

  test "полный сценарий: от создания поездки до удаления" do
    # 1. Список пока пуст
    get trips_path
    assert_response :success
    assert_select "h2", "Пока нет поездок"

    # 2. Создаём поездку
    assert_difference("Trip.count", 1) do
      post trips_path, params: { trip: {
        name: "Выходные в Париже", destination: "Париж, Франция",
        start_date: Date.current + 5, end_date: Date.current + 9,
        description: "Музеи и прогулки"
      } }
    end
    trip = Trip.last
    assert_redirected_to trip_path(trip)
    follow_redirect!
    assert_select "h1", "Выходные в Париже"

    # 3. Добавляем три остановки и удаляем среднюю
    %w[Лувр Монмартр Версаль].each do |name|
      post trip_stops_path(trip), params: { stop: { name: name } }
    end
    assert_equal %w[Лувр Монмартр Версаль], trip.stops.reload.map(&:name)

    delete trip_stop_path(trip, trip.stops.second)
    assert_equal %w[Лувр Версаль], trip.stops.reload.map(&:name)
    assert_equal [1, 2], trip.stops.map(&:position)

    # 4. Добавляем пункты подготовки и отмечаем один
    %w[Билеты Отель Виза].each do |title|
      post trip_checklist_items_path(trip), params: { checklist_item: { title: title } }
    end
    patch trip_checklist_item_path(trip, trip.checklist_items.first)
    assert_equal 33, trip.progress_percent
    get trip_path(trip)
    assert_match "33%", response.body

    # 5. Меняем статус: запланировать, затем завершить
    patch plan_trip_path(trip)
    assert trip.reload.planned?
    patch complete_trip_path(trip)
    assert trip.reload.completed?

    # 6. Редактируем
    patch trip_path(trip), params: { trip: { name: "Париж навсегда" } }
    assert_redirected_to trip_path(trip)
    assert_equal "Париж навсегда", trip.reload.name

   # 7. Удаляем вместе с остановками и пунктами
    assert_difference("Trip.count", -1) do
        delete trip_path(trip)
    end

    assert_redirected_to trips_path

    assert_equal 0, Stop.where(trip_id: trip.id).count
    assert_equal 0, ChecklistItem.where(trip_id: trip.id).count
  end

  # --- ответвление 1: чужая поездка ---

  test "другой пользователь не может открыть, изменить или удалить чужую поездку" do
    trip = make_trip(@user)

    other = User.create!(name: "Борис", email: "boris@example.com", password: "password123")
    sign_in(other)

    get trip_path(trip)
    assert_response :not_found

    patch trip_path(trip), params: { trip: { name: "Взлом" } }
    assert_response :not_found
    assert_equal "Поездка", trip.reload.name

    assert_no_difference("Trip.count") { delete trip_path(trip) }
    assert_response :not_found

    get trips_path
    assert_select "h2", "Пока нет поездок"
  end

  # --- ответвление 2: гость без входа ---

  test "гость перенаправляется на страницу входа" do
    delete logout_path

    get trips_path
    assert_redirected_to login_path

    assert_no_difference("Trip.count") do
      post trips_path, params: { trip: { name: "Тест", start_date: Date.current, end_date: Date.current } }
    end
    assert_redirected_to login_path
  end

  # --- ответвление 3: невалидные данные ---

  test "дата окончания раньше даты начала: поездка не создаётся" do
    assert_no_difference("Trip.count") do
      post trips_path, params: { trip: {
        name: "Ошибка", start_date: Date.current + 5, end_date: Date.current + 1
      } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors li", /раньше/
  end

  # --- ответвление 4: недопустимая смена статуса ---

  test "нельзя завершить поездку, которая ещё в черновиках" do
    trip = make_trip(@user)

    patch complete_trip_path(trip)

    assert_redirected_to trip_path(trip)
    assert_equal "Нельзя изменить статус поездки.", flash[:alert]
    assert trip.reload.draft?
  end

  private

  def make_trip(user)
    Trip.create!(user: user, name: "Поездка",
                 start_date: Date.current + 5, end_date: Date.current + 7)
  end
end