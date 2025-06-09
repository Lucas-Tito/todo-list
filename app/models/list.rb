class List < ApplicationRecord
  has_many :tasks, dependent: :destroy
  validates :name, presence: true

  before_create :set_position

  default_scope { order(position: :asc) }

  private

  def set_position
    self.position = List.maximum(:position).to_i + 1
  end
end