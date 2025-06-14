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
            # Insere o novo board ANTES do formulário/botão de criação
            turbo_stream.before("new_board_form", partial: "boards/board",
              locals: { board: @board, current_board: @board, start_editing_name: true }),
            
            # Limpa as listas e tarefas da tela para exibir as do novo board (que estão vazias)
            turbo_stream.update("lists_container", "")
          ]
        end
        format.html { redirect_to root_path, notice: 'Board criado com sucesso.' }
      else
        format.html do
          # Lógica para lidar com erro em requisição HTML
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

    # Se o board excluído era o que estava ativo na sessão,
    # define o primeiro board da lista como o novo ativo.
    if session[:board_id] == @board.id
      session[:board_id] = Board.order(:name).first&.id
    end

    respond_to do |format|
      # Para requisições Turbo Stream e HTML, a melhor resposta é um redirecionamento.
      # O Turbo vai interceptar e fazer a transição de forma inteligente.
      # A notice garante que o usuário veja uma confirmação.
      format.turbo_stream { redirect_to root_path, notice: 'Board excluído com sucesso.' }
      format.html { redirect_to root_path, notice: "Board excluído com sucesso.", status: :see_other }
    end
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end

  # Usa .fetch para não quebrar se o param 'board' não existir
  def board_params
    params.fetch(:board, {}).permit(:name)
  end

end