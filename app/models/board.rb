class Board < ApplicationRecord
  # A board can have many lists, and they should be ordered by their position.
  # When a board is deleted, all of its associated lists are also deleted.
  has_many :lists, -> { order(position: :asc) }, dependent: :destroy

  # The name of the board is mandatory.
  validates :name, presence: true
end