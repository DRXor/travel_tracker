class TripMembership < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  validates :user_id, uniqueness: { scope: :trip_id, message: "уже участвует в поездке" }
  validate :user_is_not_owner

  private

  def user_is_not_owner
    errors.add(:user, "уже владелец этой поездки") if trip && user_id == trip.user_id
  end
end
