class Task < ApplicationRecord
  belongs_to :board

  enum :priority, { low: 0, medium: 1, high: 2 } # SÍMBOLO + HASH

  validates :title, presence: true
  validates :board_id, presence: true

  # Scopes para separar tarefas concluídas e não concluídas
  scope :completed, -> { where.not(completed_at: nil).order(completed_at: :desc) }
  scope :uncompleted, -> { where(completed_at: nil).order(created_at: :asc) }

  # Método para marcar como concluída, agora funciona como um toggle
  def complete!
    if completed?
      update(completed_at: nil) # Reverte para pendente
    else
      update(completed_at: Time.current) # Marca como concluída
    end
  end

  def completed?
    completed_at.present?
  end

  # Método para "snooze" (adiar)
  # Você pode definir a lógica de quanto tempo adiar, por exemplo, 1 dia
  def snooze!(duration = 1.day)
    return unless due_date # Só adia se tiver data de execução
    update(due_date: due_date + duration)
  end
end