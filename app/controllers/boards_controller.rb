  # app/controllers/boards_controller.rb
class BoardsController < ApplicationController
  before_action :set_board, only: [:show, :edit, :update, :destroy] # Ensure this line is present and correct

  # POST /boards or /boards.json
  def create
    @board = Board.new(board_params)

    respond_to do |format|
      if @board.save
        format.html { redirect_to board_url(@board), notice: "Board was successfully created." }
        format.json { render :show, status: :created, location: @board }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /boards/1 or /boards/1.json
  def update
    respond_to do |format|
      if @board.update(board_params)
        format.html { redirect_to board_url(@board), notice: "Board was successfully updated." }
        format.json { render json: { status: 'ok', name: @board.name, description: @board.description }, status: :ok } # Send back updated fields
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # ... other actions like destroy ...

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_board
      @board = Board.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def board_params
      params.require(:board).permit(:name, :description, :color) # Added :color based on schema
    end
  end

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def destroy
  end

