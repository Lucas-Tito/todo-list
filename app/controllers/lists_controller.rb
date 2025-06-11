class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]

  def move
    @list = List.find(params[:id])
    @list.insert_at(params[:position].to_i)
    head :ok
  end

  # GET /lists
  def index
    # Only show lists from the current board.
    @lists = @current_board.lists.order(:position)
  end

  # GET /list/new
  def new
    @list = @current_board.lists.build
  end

  # POST /lists or /lists.json
  def create
    permitted_params = list_params

    # Set a default name if it's blank, ensuring it's unique
    if permitted_params[:name].blank?
      base_name = "Nova Lista"
      new_name = base_name
      i = 1
      while @current_board.lists.exists?(name: new_name)
        new_name = "#{base_name} (#{i})"
        i += 1
      end
      permitted_params[:name] = new_name
    end

    @list = @current_board.lists.build(permitted_params)

    respond_to do |format|
      if @list.save
        format.turbo_stream do
          # Alterado de 'append' para 'before' para inserir a nova lista
          # antes do botão "Nova Lista" (o placeholder).
          render turbo_stream: turbo_stream.before(
            "add_new_list_placeholder",
            partial: "lists/list",
            locals: { list: @list, start_editing_name: true }
          )
        end
        format.html { redirect_to root_path, notice: "List was successfully created." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("lists_list_container",
                                                   partial: "shared/turbo_flash",
                                                   locals: { alert: @list.errors.full_messages.join(", ") }),
                 status: :unprocessable_entity
        end
        format.html do
          @lists = @current_board.lists.order(:position)
          flash.now[:alert] = @list.errors.full_messages.join(", ")
          render 'tasks/index', status: :unprocessable_entity
        end
      end
    end
  end

  # GET /lists/:id
  def show
    # @list is defined by before_action
  end

  # GET /lists/:id/edit
  def edit
    # @list is defined by before_action
  end

  # PATCH/PUT /lists/:id or /lists/:id.json
  def update
    # @list is defined by before_action
    respond_to do |format|
      if @list.update(list_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@list),
                                                   partial: "lists/list",
                                                   locals: { list: @list })
        end
        format.html { redirect_to tasks_path, notice: "list was successfully updated." }
        format.json { render json: { id: @list.id, name: @list.name, description: @list.description }, status: :ok }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@list),
                                                   partial: "lists/list",
                                                   locals: { list: @list }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/:id
  def destroy
    # @list is defined by before_action
    @list.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@list)) }
      format.html { redirect_to tasks_path, notice: "list excluded successfully.", status: :see_other }
    end
  end

  private

  def set_list
    @list = List.find(params[:id])
  end

  def list_params
    params.require(:list).permit(:name, :description, :color)
  end
end