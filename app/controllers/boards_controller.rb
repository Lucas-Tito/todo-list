class BoardsController < ApplicationController
  before_action :set_board, only: [:update, :destroy]


  def index
    @boards = Board.order(:name)
    @lists = @current_board.lists.includes(:tasks).order(:position) if @current_board
  end

  # POST /boards or /boards.turbo_stream
  def create
    @board = Board.new(board_params)

    respond_to do |format|
      if @board.save
        session[:board_id] = @board.id

        format.turbo_stream do
          render turbo_stream: [
            # Insert new board BEFORE create button
            turbo_stream.before("new_board_form", partial: "boards/board",
              locals: { board: @board, current_board: @board, start_editing_name: true }),
            
            # Clear lists and tasks from screen to show the ones from the new board (which are empty)
            turbo_stream.update("lists_container", "")
          ]
        end
        format.html { redirect_to root_path, notice: 'Board criado com sucesso.' }
      else
        format.html do
          # Error logic to handle html request
          @boards = Board.order(:name)
          @lists = @current_board&.lists&.includes(:tasks)&.order(:position)
          flash.now[:alert] = @board.errors.full_messages.join(", ")
          render 'tasks/index', status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @board.update(board_params)
        format.json { render json: @board, status: :ok }
        format.html { redirect_to root_path, notice: 'Board atualizado.' }
      else
        format.json { render json: { errors: @board.errors.full_messages }, status: :unprocessable_entity }
        format.html { render 'tasks/index', status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @board.destroy

    # If the deleted board was the active one,
    # defines first board from list as active.
    if session[:board_id] == @board.id
      session[:board_id] = Board.order(:name).first&.id
    end

    respond_to do |format|

      # For Turbo Stream and HTML requests, the best response is a redirect.
      # Turbo will intercept and handle the transition intelligently.
      # The notice ensures that the user sees a confirmation.
      format.turbo_stream { redirect_to root_path, notice: 'Board excluído com sucesso.' }
      format.html { redirect_to root_path, notice: "Board excluído com sucesso.", status: :see_other }
    end
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  # Use .fetch to prevent crash if 'board' param doesn't exists
  def board_params
    params.fetch(:board, {}).permit(:name)
  end

end