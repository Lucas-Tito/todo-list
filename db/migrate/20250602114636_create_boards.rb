class CreateBoards < ActiveRecord::Migration[8.0]
  def change
    create_table :boards do |t|
      t.string :name
      t.text :description
      t.string :color

      t.timestamps
    end
  end
end
