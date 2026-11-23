require "test_helper"

class PlaceRecommendationServiceTest < ActiveSupport::TestCase
  test "returns an error when destination is blank" do
    result = PlaceRecommendationService.new("").call

    assert_equal false, result[:success]
    assert_empty result[:places]
    assert_match(/город назначения/, result[:error])
  end

  test "returns an error when destination cannot be geocoded" do
    test_service = Class.new(PlaceRecommendationService) do
      private

      def geocode_destination
        nil
      end
    end

    result = test_service.new("Несуществующий город").call

    assert_equal false, result[:success]
    assert_empty result[:places]
    assert_match(/Не удалось определить город/, result[:error])
  end

  test "returns places when destination is geocoded" do
    test_service = Class.new(PlaceRecommendationService) do
      private

      def geocode_destination
        {
          latitude: 48.8566,
          longitude: 2.3522
        }
      end

      def fetch_places(_coordinates)
        [
          {
            name: "Эйфелева башня",
            category: "Достопримечательность",
            latitude: 48.8584,
            longitude: 2.2945
          }
        ]
      end
    end

    result = test_service.new("Париж, Франция").call

    assert_equal true, result[:success]
    assert_equal 1, result[:places].size
    assert_equal "Эйфелева башня", result[:places].first[:name]
    assert_nil result[:error]
  end
end
