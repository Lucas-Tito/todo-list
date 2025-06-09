class BoardsController < ApplicationController
  # This controller handles actions related to boards.

  # Creates a new board.
  def create
    @board = Board.new(board_params)

    if @board.save
      # If saved successfully, switch to the new board and redirect.
      session[:board_id] = @board.id
      redirect_to root_path, notice: "Board criado com sucesso."
    else
      # If there's an error, reload the necessary data and re-render the main page.
      @boards = Board.all.order(:name)
      @lists = @current_board.lists.includes(:tasks).order(:position)
      flash.now[:alert] = @board.errors.full_messages.join(", ")
      render 'tasks/index', status: :unprocessable_entity
    end
  end

  private

  # Defines the permitted parameters for creating a board.
  def board_params
    params.require(:board).permit(:name)
  end
end