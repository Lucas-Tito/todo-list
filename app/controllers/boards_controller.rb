# app/controllers/boards_controller.rb
class BoardsController < ApplicationController
  before_action :set_board, only: [:show, :edit, :update, :destroy]

  # GET /boards
  def index
    @boards = Board.order(created_at: :asc)
  end

  # GET /boards/new
  def new
    @board = Board.new
  end

  # POST /boards or /boards.json
  def create
    # --- Linhas de Diagnóstico ---
    Rails.logger.debug "--- BOARDS_CONTROLLER#CREATE ---"
    Rails.logger.debug "Request Format Symbol: #{request.format.symbol.inspect}" # Crucial!
    Rails.logger.debug "Request Content-Type: #{request.content_type.inspect}"
    Rails.logger.debug "Request Accept Header: #{request.headers['Accept'].inspect}"
    # A linha com turbo_stream_request? foi removida.
    # Em vez disso, podemos usar request.format.turbo_stream? se precisarmos de uma verificação booleana.
    Rails.logger.debug "Is request.format.turbo_stream?: #{request.format.turbo_stream?.inspect}"

    if Mime::Type.lookup_by_extension(:turbo_stream)
      Rails.logger.debug "Mime[:turbo_stream] symbol: #{Mime[:turbo_stream].symbol.inspect}"
      Rails.logger.debug "Mime[:turbo_stream] string: #{Mime[:turbo_stream].to_s.inspect}"
    else
      Rails.logger.warn "Mime type for :turbo_stream NOT FOUND in Mime::Type lookup!"
    end
    # --- Fim das Linhas de Diagnóstico ---

    @board = Board.new(board_params_for_create)
    @board.name = "Novo Board" if @board.name.blank?

    respond_to do |format|
      if @board.save
        format.turbo_stream do
          Rails.logger.debug "Board SAVED - Responding with TURBO_STREAM"
          render turbo_stream: [
            turbo_stream.replace("add_new_board_placeholder",
                                 partial: "boards/board",
                                 locals: { board: @board, start_editing_name: true }),
            turbo_stream.append("boards_list_container",
                                partial: "boards/add_new_board_placeholder")
          ]
        end
        format.html do
          Rails.logger.debug "Board SAVED - Responding with HTML"
          redirect_to tasks_path, notice: "Board criado com sucesso."
        end
      else
        format.turbo_stream do
          Rails.logger.debug "Board NOT SAVED - Responding with TURBO_STREAM (errors), Status: unprocessable_entity"
          render turbo_stream: turbo_stream.prepend("boards_list_container",
                                                   partial: "shared/turbo_flash",
                                                   locals: { alert: @board.errors.full_messages.join(", ") }),
                 status: :unprocessable_entity
        end
        format.html do
          Rails.logger.debug "Board NOT SAVED - Responding with HTML (errors)"
          @boards = Board.order(:name)
          flash.now[:alert] = @board.errors.full_messages.join(", ")
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  # GET /boards/:id
  def show
    # @board é definido pelo before_action
  end

  # GET /boards/:id/edit
  def edit
    # @board é definido pelo before_action
  end

  # PATCH/PUT /boards/:id or /boards/:id.json
  def update
    # @board é definido pelo before_action
    respond_to do |format|
      if @board.update(board_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@board),
                                                   partial: "boards/board",
                                                   locals: { board: @board })
        end
        format.html { redirect_to tasks_path, notice: "Board was successfully updated." }
        format.json { render json: { id: @board.id, name: @board.name, description: @board.description }, status: :ok }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@board),
                                                   partial: "boards/board",
                                                   locals: { board: @board }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @board.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/:id
  def destroy
    # @board é definido pelo before_action
    @board.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@board)) }
      format.html { redirect_to tasks_path, notice: "Board excluído com sucesso.", status: :see_other }
    end
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :description, :color)
  end

  def board_params_for_create
    params.fetch(:board, {}).permit(:name, :description, :color)
  end

end
