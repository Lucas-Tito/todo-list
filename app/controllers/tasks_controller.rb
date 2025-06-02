# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :complete, :snooze]
  before_action :load_boards, only: [:new, :edit, :create, :update] # Adiciona esta linha


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

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to @task, notice: 'Tarefa criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: 'Tarefa atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
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
end