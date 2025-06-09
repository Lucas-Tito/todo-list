class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]


  def move
    @list = List.find(params[:id])
    @list.insert_at(params[:position].to_i)
    head :ok
  end

  # GET /lists
  def index
    @lists = List.order(created_at: :asc)
  end

  # GET /list/new
  def new
    @list = List.new
  end

  # POST /lists or /lists.json
  def create
    @list = List.new(list_params_for_create)
    @list.name = "Nova Lista" if @list.name.blank?

    respond_to do |format|
      if @list.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("add_new_list_placeholder",
                                 partial: "lists/list",
                                 locals: { list: @list, start_editing_name: true }),
            turbo_stream.append("lists_list_container",
                                partial: "lists/add_new_list_placeholder")
          ]
        end
        format.html do
          redirect_to tasks_path, notice: "List criado com sucesso."
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("lists_list_container",
                                                   partial: "shared/turbo_flash",
                                                   locals: { alert: @list.errors.full_messages.join(", ") }),
                 status: :unprocessable_entity
        end
        format.html do
          @lists = List.order(:name)
          flash.now[:alert] = @list.errors.full_messages.join(", ")
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  # GET /lists/:id
  def show
    # @list é definido pelo before_action
  end

  # GET /lists/:id/edit
  def edit
    # @list é definido pelo before_action
  end

  # PATCH/PUT /lists/:id or /lists/:id.json
  def update
    # @list é definido pelo before_action
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
    # @list é definido pelo before_action
    @list.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@list)) }
      format.html { redirect_to tasks_path, notice: "list excluído com sucesso.", status: :see_other }
    end
  end

  private

  def set_list
    @list = List.find(params[:id])
  end

  def list_params
    params.require(:list).permit(:name, :description, :color)
  end

  def list_params_for_create
    params.fetch(:list, {}).permit(:name, :description, :color)
  end

end
