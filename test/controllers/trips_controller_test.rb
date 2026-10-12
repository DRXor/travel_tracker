
require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)

    post login_path, params: {
      email: @user.email,
      password: "password123"
    }
  end

  test "should get index" do
    get trips_url

    assert_response :success
  end

  test "should get new" do
    get new_trip_url

    assert_response :success
  end

  test "should create trip" do
    assert_difference("Trip.count", 1) do
      post trips_url, params: {
        trip: {
          name: "Weekend trip",
          destination: "Paris",
          start_date: "2026-10-20",
          end_date: "2026-10-22",
          description: "A short trip"
        }
      }
    end

    assert_redirected_to trip_url(Trip.last)
  end

  test "should show trip" do
    get trip_url(trips(:one))

    assert_response :success
  end

  test "should destroy trip" do
    assert_difference("Trip.count", -1) do
      delete trip_url(trips(:one))
    end

    assert_redirected_to trips_url
  end
end
