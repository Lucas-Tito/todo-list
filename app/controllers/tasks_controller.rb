# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :set_board_for_creation, only: [:create]
  before_action :set_task_and_board, only: [:show, :edit, :update, :destroy, :complete, :snooze]
  before_action :load_boards_for_forms, only: [:new, :edit]



  def index
    # Você pode querer filtrar tasks por board aqui ou mostrar todos
    @boards = Board.includes(:tasks).all # Carrega boards e suas tasks
    # Ou apenas @tasks = Task.all se a visualização for global
  end

  def show
  end

  def new
    @task = Task.new
  end

  # POST /boards/:board_id/tasks
  def create
    @task = @board.tasks.build(task_params_for_create)
    @task.title = "New Task" if @task.title.blank? # Default title for immediate editing

    respond_to do |format|
      if @task.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "tasks_list_board_#{@board.id}", # DOM ID of the tasks container for this board
            partial: "tasks/task",
            locals: { task: @task, board: @board, start_editing_title: true } # Flag for immediate edit
          )
        end
        format.html { redirect_to board_url(@board), notice: 'Task was successfully created.' }
      else
        format.turbo_stream do
          # Prepend errors to a dedicated flash area
          render turbo_stream: turbo_stream.prepend("flash_messages_board_#{@board.id}",
                                                    partial: "shared/turbo_flash",
                                                    locals: { alert: @task.errors.full_messages.join(", ") }),
                 status: :unprocessable_entity
        end
        format.html do
          # Fallback for non-JS or if you have a dedicated 'new' page
          @tasks = @board.tasks # Reload tasks for the board view if re-rendering 'boards/show'
          render 'boards/show', status: :unprocessable_entity # Or your 'new' task view
        end
      end
    end
  end

  def edit
  end

  # PATCH /tasks/:id
  def update
    respond_to do |format|
      if @task.update(task_params_for_update)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@task), # Target the specific task's DOM ID
            partial: "tasks/task",
            locals: { task: @task, board: @board } # Pass board for path helpers in partial
          )
        end
        format.json { render json: @task, status: :ok } # For Stimulus controller updates
        format.html { redirect_to board_url(@task.board), notice: 'Task was successfully updated.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@task),
                                                    partial: "tasks/task",
                                                    locals: { task: @task, board: @board }), # Re-render with errors
                 status: :unprocessable_entity
        end
        format.json { render json: @task.errors, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity } # Or 'boards/show'
      end
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_url, notice: 'Tarefa excluída com sucesso.'
  end

  # Ação para marcar como concluída
  def complete
    @task.complete!
    redirect_to tasks_url, notice: 'Tarefa marcada como concluída.'
  end

  # Ação para adiar (snooze)
  def snooze
    @task.snooze! # Pode passar uma duração customizada se desejar
    redirect_to tasks_url, notice: 'Tarefa adiada.'
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time, :board_id)
  end

  def load_boards # Novo método
    @boards = Board.all.order(:name) # Carrega todos os boards para dropdowns, por exemplo
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