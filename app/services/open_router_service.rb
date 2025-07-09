# Service to interact with the OpenRouter API for generating task summaries.
class OpenRouterService
  # Base URI for the OpenRouter API.
  include HTTParty
  base_uri "https://openrouter.ai/api/v1"

  # Available free models in order of preference
  FREE_MODELS = [
    "deepseek/deepseek-chat-v3-0324:free",
    "deepseek/deepseek-chat:free",
    "mistralai/mistral-7b-instruct:free",
    "huggingface/zephyr-7b-beta:free",
    "openchat/openchat-7b:free",
    "meta-llama/llama-3.2-3b-instruct:free",
    "microsoft/phi-3-mini-128k-instruct:free"
  ].freeze

  # Default parameters for the API
  DEFAULT_PARAMS = {
    temperature: 0.7,    # Controls creativity
    max_tokens: 500,     # Maximum number of tokens in response (increased)
    top_p: 0.9          # Controls response diversity
  }.freeze

  # Initializes the service with tasks and an optional controller context.
  # @param tasks [ActiveRecord::Relation] the tasks to be summarized.
  # @param controller [ApplicationController] the controller instance, used for flash messages.
  # @param model [String] the AI model to use (optional).
  def initialize(tasks, controller = nil, model = nil)
    @tasks = tasks
    @controller = controller
    @model = model || best_available_model
    # Sets the authorization token from Rails credentials.
    @options = {
      headers: {
        "Authorization" => "Bearer #{Rails.application.credentials.open_router_token}",
        "Content-Type" => "application/json"
      }
    }
  end

  # Main method to generate the summary.
  def call
    # Returns a message if there are no tasks to summarize.
    return I18n.t('open_router.no_tasks') if @tasks.empty?

    # Debug: Log the user message to see what's being sent
    Rails.logger.info "User message being sent to AI:"
    Rails.logger.info user_message
    Rails.logger.info "=" * 50

    # Try different models if the first one fails
    attempt_with_fallback
  rescue StandardError => e
    # Rescues from standard errors (e.g., network issues) and returns an error message.
    Rails.logger.error "OpenRouter Service Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    I18n.t('open_router.error_messages.connection_error', message: e.message)
  end

  private

  # Prepares the request body for the OpenRouter API.
  def body
    {
      model: @model,
      messages: [
        { role: "system", content: system_message },
        { role: "user", content: user_message }
      ]
    }.merge(DEFAULT_PARAMS)
  end

  # Creates a detailed user message with the list of tasks.
  def user_message
    return I18n.t('open_router.no_tasks_user_message') if @tasks.empty?

    # Debug: Log task details before processing
    Rails.logger.info "Total tasks received: #{@tasks.count}"
    @tasks.each do |task|
      Rails.logger.info "Task: #{task.title}, Priority: '#{task.priority}', Due: #{task.due_date}"
    end

    # Get unique boards from the tasks
    boards = @tasks.joins(:list).includes(list: :board).map { |task| task.list.board }.uniq
    board_names = boards.map(&:name).join(", ")

    # Debug: Log board information
    Rails.logger.info "Boards found: #{boards.count}"
    boards.each { |board| Rails.logger.info "Board: #{board.name}" }
    Rails.logger.info "Board names string: '#{board_names}'"

    # Categorizes tasks by priority (supports both Portuguese and English)
    high_priority = @tasks.select { |task| ["alta", "high"].include?(task.priority) }
    medium_priority = @tasks.select { |task| ["média", "medium"].include?(task.priority) }
    low_priority = @tasks.select { |task| ["baixa", "low"].include?(task.priority) }
    no_priority = @tasks.select { |task| task.priority.nil? || task.priority.empty? || !["alta", "high", "média", "medium", "baixa", "low"].include?(task.priority) }

    # Debug: Log priority categories
    Rails.logger.info "High priority: #{high_priority.count} tasks"
    Rails.logger.info "Medium priority: #{medium_priority.count} tasks"
    Rails.logger.info "Low priority: #{low_priority.count} tasks"
    Rails.logger.info "No priority: #{no_priority.count} tasks"

    # Identifies overdue or upcoming tasks
    overdue_tasks = @tasks.select { |task| task.due_date && task.due_date < Date.current }
    upcoming_tasks = @tasks.select { |task| task.due_date && task.due_date.between?(Date.current, Date.current + 3.days) }

    message = I18n.t('open_router.boards_analysis', board_names: board_names) + "\n\n"
    
    if high_priority.any?
      message += I18n.t('open_router.priority.high') + "\n"
      high_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if medium_priority.any?
      message += I18n.t('open_router.priority.medium') + "\n"
      medium_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if low_priority.any?
      message += I18n.t('open_router.priority.low') + "\n"
      low_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if no_priority.any?
      message += I18n.t('open_router.priority.none') + "\n"
      no_priority.each { |task| message += format_task(task) }
      message += "\n"
    end

    # If no tasks in priority categories, show all tasks
    if high_priority.empty? && medium_priority.empty? && low_priority.empty? && no_priority.empty?
      message += I18n.t('open_router.priority.all') + "\n"
      @tasks.each { |task| message += format_task(task) }
      message += "\n"
    end

    if overdue_tasks.any?
      message += I18n.t('open_router.alerts.overdue', count: overdue_tasks.count) + "\n"
    end
    
    if upcoming_tasks.any?
      message += I18n.t('open_router.alerts.upcoming', count: upcoming_tasks.count) + "\n"
    end

    message += "\n" + I18n.t('open_router.total', count: @tasks.count, boards: boards.count)
    message += I18n.t('open_router.recommendations_context')
    
    message
  end

  # Formats an individual task
  def format_task(task)
    # Debug: Log task details
    Rails.logger.info "Task details: ID=#{task.id}, Title='#{task.title}', Priority=#{task.priority}, Due=#{task.due_date}"
    
    due_info = if task.due_date
      days_diff = (task.due_date - Date.current).to_i
      case days_diff
      when 0
        " (#{I18n.t('open_router.due_dates.today')})"
      when 1
        " (#{I18n.t('open_router.due_dates.tomorrow')})"
      when -1
        " (#{I18n.t('open_router.due_dates.yesterday')})"
      when 2..7
        " (#{I18n.t('open_router.due_dates.in_days', days: days_diff)})"
      when -7..-1
        " (#{I18n.t('open_router.due_dates.overdue_days', days: days_diff.abs)})"
      else
        date_format = I18n.locale == :en ? '%m/%d/%Y' : '%d/%m/%Y'
        " (#{I18n.t('open_router.due_dates.date_format', date: task.due_date.strftime(date_format))})"
      end
    else
      ""
    end
    
    formatted_task = "- \"#{task.title}\"#{due_info}\n"
    Rails.logger.info "Formatted task: #{formatted_task.strip}"
    formatted_task
  end

  # Formats an individual task with board information
  def format_task_with_board(task)
    # Debug: Log task details
    Rails.logger.info "Task details: ID=#{task.id}, Title='#{task.title}', Priority=#{task.priority}, Due=#{task.due_date}"
    
    board_name = task.list.board.name
    due_info = if task.due_date
      days_diff = (task.due_date - Date.current).to_i
      case days_diff
      when 0
        " (#{I18n.t('open_router.due_dates.today')})"
      when 1
        " (#{I18n.t('open_router.due_dates.tomorrow')})"
      when -1
        " (#{I18n.t('open_router.due_dates.yesterday')})"
      when 2..7
        " (#{I18n.t('open_router.due_dates.in_days', days: days_diff)})"
      when -7..-1
        " (#{I18n.t('open_router.due_dates.overdue_days', days: days_diff.abs)})"
      else
        date_format = I18n.locale == :en ? '%m/%d/%Y' : '%d/%m/%Y'
        " (#{I18n.t('open_router.due_dates.date_format', date: task.due_date.strftime(date_format))})"
      end
    else
      ""
    end
    
    formatted_task = "- \"#{task.title}\" [#{board_name}]#{due_info}\n"
    Rails.logger.info "Formatted task: #{formatted_task.strip}"
    formatted_task
  end

  # Defines the system message to guide the AI's response.
  def system_message
    I18n.t('open_router.system_prompt')
  end

  # Handles API errors and sets a flash message if a controller context is available.
  def handle_error(response)
    error_details = case response.code
    when 404
      I18n.t('open_router.error_messages.model_not_found')
    when 401
      I18n.t('open_router.error_messages.invalid_token')
    when 429
      I18n.t('open_router.error_messages.rate_limit')
    when 500, 502, 503
      I18n.t('open_router.error_messages.server_error')
    else
      response.message
    end
    
    error_message = I18n.t('open_router.error_messages.generation_error', details: error_details, code: response.code)
    
    # Sets a flash alert if a controller is present.
    if @controller
      @controller.flash.now[:alert] = error_message
    end
    
    error_message
  end

  # Selects the best available free model
  def best_available_model
    FREE_MODELS.first
  end

  # Attempts to generate summary with fallback to different models
  def attempt_with_fallback
    models_to_try = [@model] + FREE_MODELS.reject { |m| m == @model }
    
    models_to_try.each_with_index do |model, index|
      @model = model
      Rails.logger.info "Trying model: #{model} (attempt #{index + 1}/#{models_to_try.count})"
      
      response = self.class.post("/chat/completions", @options.merge(body: body.to_json))
      
      if response.success?
        return response.dig("choices", 0, "message", "content")
      else
        Rails.logger.error "Model #{model} failed: #{response.code} - #{response.message}"
        Rails.logger.error "Response body: #{response.body}" if response.body
        
        # If this is the last model, handle the error
        if index == models_to_try.count - 1
          return handle_error(response)
        end
      end
    end
  end
end