class AddListToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :list, null: false, foreign_key: true
  end
end
