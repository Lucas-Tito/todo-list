class TasksController < ApplicationController
  before_action :set_list_from_url_params, only: [:create]
  # Garantindo que todas as actions necessárias estejam aqui
  before_action :set_task_and_list_via_task, only: [:update, :destroy, :complete, :snooze]

  def create
    @task = @list.tasks.build(title: "Nova Tarefa")
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

  # *** AÇÃO SNOOZE ADICIONADA AQUI ***
  def snooze
    @task.snooze! # Chama o método do seu modelo Task
    # Após o snooze, a data muda, então atualizamos a UI da mesma forma
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
    # Adicionando de volta :completed_at para que o formulário de edição funcione, se necessário
    params.require(:task).permit(:title, :description, :priority, :due_date, :due_time, :completed_at)
  end
end
