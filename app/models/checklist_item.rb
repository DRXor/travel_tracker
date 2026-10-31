class ChecklistItem < ApplicationRecord
  belongs_to :trip

  validates :title, presence: true, length: { maximum: 120 }

  def toggle_done!
    update!(done: !done)
  end
end