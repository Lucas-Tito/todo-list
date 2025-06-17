class TasksController < ApplicationController
  before_action :set_list_from_url_params, only: [:create]
  before_action :set_task_and_list_via_task, only: [:update, :destroy, :complete, :snooze]

  def create
    @task = @list.tasks.build
    @task.save
    respond_to_turbo_stream_update
  end

  def destroy
    @task.destroy
    respond_to_turbo_stream_update
  end

  def complete
    @task.complete!
    respond_to_turbo_stream_update
  end

  def update
    respond_to do |format|
      if @task.update(task_params_for_update)
        format.json { render json: @task, status: :ok }
        format.html { redirect_to root_path, notice: 'Tarefa atualizada.' }
      else
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def snooze
    @task.snooze! 
    # After snoozer, the date updates, so the UI is updated
    respond_to_turbo_stream_update
  end

  private

  def respond_to_turbo_stream_update
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          dom_id(@list, :tasks_container),
          partial: "lists/tasks_container",
          locals: { list: @list, start_editing_title_for_task_id: @task&.id }
        )
      end
      format.html { redirect_to root_path }
    end
  end

  def set_list_from_url_params
    @list = List.find(params[:list_id])
  end

  def set_task_and_list_via_task
    @task = Task.find(params[:id])
    @list = @task.list
  end

  def task_params_for_update
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time, :completed_at)
  end
end
