class PlaceRecommendationsController < ApplicationController
  before_action :require_login
  before_action :set_trip

  def index
    result = PlaceRecommendationService.new(@trip.destination).call

    @places = result[:places]
    @error = result[:error]

    render partial: "place_recommendations/results",
           locals: {
             trip: @trip,
             places: @places,
             error: @error
           }
  end

  private

  def set_trip
    @trip = current_user.accessible_trips.find(params[:id])
  end
end