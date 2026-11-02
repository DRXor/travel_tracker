class StopsController < ApplicationController
  before_action :require_login
  before_action :set_trip

  def create
    stop = @trip.stops.build(params.require(:stop).permit(:name))

    if stop.save
      redirect_to trip_path(@trip), notice: "Остановка добавлена."
    else
      redirect_to trip_path(@trip), alert: stop.errors.full_messages.to_sentence
    end
  end

  def destroy
    @trip.stops.find(params[:id]).destroy
    redirect_to trip_path(@trip), notice: "Остановка удалена."
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end