class AddBoardIdToLists < ActiveRecord::Migration[8.0]
  def change
    # Add the reference, allowing it to be null initially to handle existing lists.
    add_reference :lists, :board, null: true, foreign_key: true

    # Create a default board and assign existing lists to it.
    # This is a good place for a data migration.
    reversible do |dir|
      dir.up do
        # Create a default board if none exist
        default_board = Board.first_or_create!(name: "Meu Primeiro Board")
        # Assign all lists without a board to the default board
        List.where(board_id: nil).update_all(board_id: default_board.id)
      end
    end

    # Finally, change the column to not allow null values for future lists.
    change_column_null :lists, :board_id, false
  end
end