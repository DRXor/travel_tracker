class ChecklistItemsController < ApplicationController
  before_action :require_login
  before_action :set_trip

  def create
    item = @trip.checklist_items.build(params.require(:checklist_item).permit(:title))

    if item.save
      redirect_to trip_path(@trip), notice: "Пункт добавлен."
    else
      redirect_to trip_path(@trip), alert: item.errors.full_messages.to_sentence
    end
  end

  def update
    @trip.checklist_items.find(params[:id]).toggle_done!
    redirect_to trip_path(@trip)
  end

  def destroy
    @trip.checklist_items.find(params[:id]).destroy
    redirect_to trip_path(@trip), notice: "Пункт удалён."
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end