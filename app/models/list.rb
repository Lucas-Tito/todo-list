class List < ApplicationRecord
  # Include the acts_as_list gem functionality, scoping it to the board_id.
  # This means the position of a list is relative to other lists on the same board.
  acts_as_list scope: :board

  # Each list belongs to a single board.
  belongs_to :board
  # A list can have many tasks. If a list is deleted, its tasks are also deleted.
  has_many :tasks, dependent: :destroy

  # The name of the list is mandatory.
  validates :name, presence: true

  # The default order for lists is by their position in ascending order.
  default_scope { order(position: :asc) }
end