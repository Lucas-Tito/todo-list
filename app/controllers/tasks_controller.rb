# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  # For the main index page that shows all boards
  before_action :load_all_boards, only: [:index]

  # For actions that create a task for a specific board (board_id from URL)
  # The 'new' action might not be used if your form is directly on the index page.
  before_action :set_board_from_url_params, only: [:new, :create]

  # For actions that operate on a specific task (task_id from URL, board via association)
  before_action :set_task_and_board_via_task, only: [:show, :edit, :update, :destroy, :complete, :snooze]

  def index
    # @boards is loaded by the :load_all_boards before_action.
    # The view (tasks/index.html.erb) iterates through @boards to display them and their tasks.
  end

  # POST /boards/:board_id/tasks
  def create
    # @board is set by :set_board_from_url_params
    @task = @board.tasks.build(task_params_for_create)
    @task.title = "Nova Tarefa" if @task.title.blank? # Default title

    respond_to do |format|
      if @task.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "tasks_list_board_#{@board.id}",
            partial: "tasks/task",
            locals: { task: @task, board: @board, start_editing_title: true }
          )
        end
        format.html { redirect_to tasks_path, notice: 'Tarefa criada com sucesso.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "flash_messages_board_#{@board.id}", # Make sure this div exists in your view
            partial: "shared/turbo_flash",      # You'll need to create this partial
            locals: { alert: @task.errors.full_messages.join(", ") }
          ), status: :unprocessable_entity
        end
        format.html do
          load_all_boards # Ensure @boards is available for re-rendering index
          flash.now[:alert] = @task.errors.full_messages.join(", ")
          render :index, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH /tasks/:id
  def update
    # @task and @board are set by :set_task_and_board_via_task
    respond_to do |format|
      if @task.update(task_params_for_update)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: "tasks/task",
            locals: { task: @task, board: @board } # Pass board for path helpers
          )
        end
        format.json { render json: @task, status: :ok }
        format.html { redirect_to tasks_path, notice: 'Tarefa atualizada com sucesso.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@task),
                                                   partial: "tasks/task",
                                                   locals: { task: @task, board: @board }),
                 status: :unprocessable_entity
        end
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
        format.html do
          load_all_boards # For re-rendering index if edit happens there or fallback
          flash.now[:alert] = @task.errors.full_messages.join(", ")
          render :index, status: :unprocessable_entity # Or :edit if you have a separate edit page
        end
      end
    end
  end

  # GET /boards/:board_id/tasks/new (If you have a dedicated new task page)
  def new
    # @board is set by :set_board_from_url_params
    @task = @board.tasks.new
  end

  # GET /tasks/:id/edit (If you have a dedicated edit task page)
  def edit
    # @task and @board are set by :set_task_and_board_via_task
  end

  def show
    # @task and @board are set by :set_task_and_board_via_task
  end

  def destroy
    # @task and @board are set by :set_task_and_board_via_task
    @task.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@task)) }
      format.html { redirect_to tasks_path, notice: 'Tarefa excluída com sucesso.' }
    end
  end

  def complete
    # @task is set by :set_task_and_board_via_task
    @task.complete! #
    respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@task), partial: "tasks/task", locals: { task: @task, board: @task.board }) }
        format.html { redirect_to tasks_path, notice: 'Tarefa marcada como concluída.' }
    end
  end

  def snooze
    # @task is set by :set_task_and_board_via_task
    @task.snooze! #
     respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@task), partial: "tasks/task", locals: { task: @task, board: @task.board }) }
        format.html { redirect_to tasks_path, notice: 'Tarefa adiada.' }
    end
  end

  private

  def load_all_boards
    @boards = Board.includes(:tasks).order(:name)
  end

  def set_board_from_url_params
    # Used for actions like 'new' and 'create' where board_id is in the URL
    @board = Board.find(params[:board_id])
  end

  def set_task_and_board_via_task
    # Used for member actions on a task (show, edit, update, destroy, etc.)
    # Assumes shallow routes, so params[:id] is the task's ID
    @task = Task.find(params[:id])
    @board = @task.board # Get the associated board
  end

  def task_params_for_create
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time)
  end

  def task_params_for_update
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time, :completed_at)
  end

  def load_boards_for_forms
    @boards = Board.all.order(:name) #
  end

  def set_board_for_creation
    @board = Board.find(params[:board_id])
  end

  def set_task_and_board
    @task = Task.find(params[:id])
    @board = @task.board # Set @board from the task
  end

  def task_params_for_create
    # Permit attributes sent from the "add new task" form
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time)
  end

  def task_params_for_update
    # Permit attributes for updating an existing task via inline edit or form
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time, :completed_at)
  end
end