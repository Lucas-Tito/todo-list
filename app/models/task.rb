class Task < ApplicationRecord
  belongs_to :list

  enum :priority, { low: 0, medium: 1, high: 2 } # SYMBOL + HASH

  validates :title, presence: true
  validates :list_id, presence: true

  before_validation :set_default_title, on: :create

  # Scopes to separate concluded and unconcluded tasks
  scope :completed, -> { where.not(completed_at: nil).order(completed_at: :desc) }
  scope :uncompleted, -> { where(completed_at: nil).order(created_at: :asc) }

  # Method to conclude a task
  def complete!
    if completed?
      update(completed_at: nil) 
    else
      update(completed_at: Time.current) 
    end
  end

  def completed?
    completed_at.present?
  end

  # Method to postpone a task
  def snooze!(duration = 1.day)
    return unless due_date # Only postpone if theres a date
    update(due_date: due_date + duration)
  end

  private 

  # Tasks can have duplicated names
  def set_default_title
    self.title ||= I18n.t('tasks.default-name') if title.blank?
  end
end