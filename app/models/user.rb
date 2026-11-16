class User < ApplicationRecord
  has_secure_password

  has_many :trips, dependent: :destroy
  has_many :trip_memberships, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # Поездки, которые пользователь создал или в которых участвует
  def accessible_trips
    Trip.where(user_id: id).or(Trip.where(id: trip_memberships.select(:trip_id)))
  end
end
