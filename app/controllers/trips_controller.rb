class TripsController < ApplicationController
  before_action :require_login
  before_action :set_trip, only: [:show, :edit, :update, :destroy, :plan, :complete, :cancel, :restore]

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

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to trip_path(@trip), notice: "Поездка обновлена!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: "Поездка удалена!"
  end

  def plan
    change_status(:plan, "Поездка запланирована!")
  end

  def complete
    change_status(:complete, "Поездка завершена!")
  end

  def cancel
    change_status(:cancel, "Поездка отменена.")
  end

  def restore
    change_status(:restore_to_draft, "Поездка возвращена в черновики.")
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:id])
  end

  def change_status(action, message)
    if @trip.public_send(action)
      redirect_to trip_path(@trip), notice: message
    else
      redirect_to trip_path(@trip), alert: "Нельзя изменить статус поездки."
    end
  end

  def trip_params
    params.require(:trip).permit(
      :name,
      :destination,
      :start_date,
      :end_date,
      :budget,
      :description
    )
  end
end