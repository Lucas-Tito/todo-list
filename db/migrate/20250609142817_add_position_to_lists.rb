class AddPositionToLists < ActiveRecord::Migration[8.0]
  def change
    add_column :lists, :position, :integer
  end
end
