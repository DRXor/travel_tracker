class TripsController < ApplicationController
  before_action :require_login
  before_action :set_trip, only: [:show, :destroy]

  def index
    @trips = current_user.trips.order(start_date: :asc)
  end

  def new
    @trip = current_user.trips.build
  end

  def create
    @trip = current_user.trips.build(trip_params)

    if @trip.save
      redirect_to trip_path(@trip), notice: "Поездка создана!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: "Поездка удалена!"
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:id])
  end

  def trip_params
    params.require(:trip).permit(
      :name,
      :destination,
      :start_date,
      :end_date,
      :description
    )
  end
end
