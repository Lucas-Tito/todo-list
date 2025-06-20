class List < ApplicationRecord
  enum :color, {
    default: "default",
    blue: "blue",
    green: "green",
    yellow: "yellow",
    orange: "orange",
    red: "red",
    purple: "purple"
  }, prefix: :color

  COLOR_MAP = {
    "default" => "transparent",
    "blue"    => "#3b82f6",
    "green"   => "#22c55e",
    "yellow"  => "#eab308",
    "orange"  => "#f97316",
    "red"     => "#ef4444",
    "purple"  => "#8b5cf6"
  }.freeze
  
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

  before_validation :set_default_name, on: :create

    # Method to get color code.
    def self.color_hex_for(color_key)
      COLOR_MAP[color_key.to_s]
    end

  private

  def set_default_name
    return if name.present? || board.nil?

    base_name = I18n.t('lists.defaults.name')
    new_name = base_name
    i = 1
    # Ensure list name is unique
    while board.lists.exists?(name: new_name)
      new_name = "#{base_name} (#{i})"
      i += 1
    end
    self.name = new_name
  end
end