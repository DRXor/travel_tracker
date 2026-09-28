class Trip < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :destination, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "не может быть раньше даты начала")
    end
  end
end