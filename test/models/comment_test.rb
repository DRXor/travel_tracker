require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Анна", email: "comment_model@example.com", password: "password123")
    @trip = Trip.create!(user: @user, name: "Париж",
                         start_date: Date.current + 5, end_date: Date.current + 7)
  end

  # --- контекст: валидации ---

  test "текст комментария обязателен" do
    assert_not @trip.comments.build(user: @user, body: "").valid?
  end

  test "текст комментария не длиннее 500 символов" do
    assert_not @trip.comments.build(user: @user, body: "а" * 501).valid?
    assert @trip.comments.build(user: @user, body: "а" * 500).valid?
  end

  # --- контекст: ассоциации ---

  test "комментарии идут по порядку создания" do
    first  = @trip.comments.create!(user: @user, body: "Первый")
    second = @trip.comments.create!(user: @user, body: "Второй")
    assert_equal [first, second], @trip.comments.reload.to_a
  end

  test "при удалении поездки удаляются её комментарии" do
    @trip.comments.create!(user: @user, body: "Привет")
    assert_difference("Comment.count", -1) { @trip.destroy }
  end
end