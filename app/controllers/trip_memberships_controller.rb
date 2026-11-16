class TripMembershipsController < ApplicationController
  before_action :require_login

  # Приглашает только владелец (у остальных поездка не находится: 404)
  def create
    trip = current_user.trips.find(params[:trip_id])
    email = params[:email].to_s.strip.downcase
    user = User.find_by("lower(email) = ?", email)

    if user.nil?
      redirect_to trip_path(trip), alert: "Пользователь с таким email не найден. Пусть сначала зарегистрируется.", status: :see_other
      return
    end

    membership = trip.trip_memberships.build(user: user)
    if membership.save
      redirect_to trip_path(trip), notice: "#{user.name} добавлен(а) в поездку.", status: :see_other
    else
      redirect_to trip_path(trip), alert: membership.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # Владелец убирает любого участника, участник может выйти сам
  def destroy
    trip = current_user.accessible_trips.find(params[:trip_id])
    membership = trip.trip_memberships.find(params[:id])

    unless trip.owner?(current_user) || membership.user_id == current_user.id
      head :forbidden
      return
    end

    membership.destroy
    if membership.user_id == current_user.id
      redirect_to trips_path, notice: "Вы вышли из поездки.", status: :see_other
    else
      redirect_to trip_path(trip), notice: "Участник убран.", status: :see_other
    end
  end
end