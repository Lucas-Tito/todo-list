class Board < ApplicationRecord
  has_many :lists, -> { order(position: :asc) }, dependent: :destroy
  validates :name, presence: true

  before_validation :set_default_name, on: :create

  private

  def set_default_name
    return if name.present?

    base_name = "Novo Board"
    new_name = base_name
    i = 1
    # O loop garante que o nome seja único
    while Board.exists?(name: new_name)
      new_name = "#{base_name} (#{i})"
      i += 1
    end
    self.name = new_name
  end
end