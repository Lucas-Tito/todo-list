class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :priority
      t.datetime :completed_at
      t.date :due_date
      t.time :due_time

      t.timestamps
    end
  end
end
