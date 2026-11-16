require "test_helper"

class LiveCommentsTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @user = User.create!(name: "Анна", email: "live@example.com", password: "password123")
    @trip = Trip.create!(user: @user, name: "Париж",
                         start_date: Date.current + 5, end_date: Date.current + 7)
    sign_in(@user)
  end

  # --- контекст: создание комментария и рассылка ---

  test "комментарий создаётся и рассылается подписчикам поездки" do
    assert_broadcasts(@trip.to_gid_param, 2) do
      assert_difference("Comment.count", 1) do
        post trip_comments_path(@trip), params: { comment: { body: "Берём зонт!" } }, headers: TURBO
      end
    end
    assert_response :success
    assert_equal "Берём зонт!", @trip.comments.last.body
  end

  test "пустой комментарий не создаётся и не рассылается" do
    assert_no_broadcasts(@trip.to_gid_param) do
      assert_no_difference("Comment.count") do
        post trip_comments_path(@trip), params: { comment: { body: "" } }, headers: TURBO
      end
    end
    assert_response :unprocessable_entity
  end

  # --- контекст: права ---

  test "чужой комментарий нельзя изменить" do
    other = User.create!(name: "Борис", email: "boris_live@example.com", password: "password123")
    foreign = Comment.create!(trip: @trip, user: other, body: "Чужой")

    patch trip_comment_path(@trip, foreign), params: { comment: { body: "Взлом" } }

    assert_response :not_found
    assert_equal "Чужой", foreign.reload.body
  end

  test "автор может изменить и удалить свой комментарий" do
    comment = Comment.create!(trip: @trip, user: @user, body: "Было")

    patch trip_comment_path(@trip, comment), params: { comment: { body: "Стало" } }
    assert_redirected_to trip_path(@trip)
    assert_equal "Стало", comment.reload.body

    assert_difference("Comment.count", -1) { delete trip_comment_path(@trip, comment) }
    assert_redirected_to trip_path(@trip)
  end
end