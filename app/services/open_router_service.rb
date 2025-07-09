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
    return "Nenhuma tarefa para resumir." if @tasks.empty?

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
    "Ocorreu um erro ao conectar com a OpenRouter API: #{e.message}"
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
    return "Não há tarefas para resumir." if @tasks.empty?

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

    message = "Análise de tarefas dos boards: #{board_names}\n\n"
    
    if high_priority.any?
      message += "🔴 ALTA PRIORIDADE:\n"
      high_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if medium_priority.any?
      message += "🟡 MÉDIA PRIORIDADE:\n"
      medium_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if low_priority.any?
      message += "🟢 BAIXA PRIORIDADE:\n"
      low_priority.each { |task| message += format_task(task) }
      message += "\n"
    end
    
    if no_priority.any?
      message += "⚪ SEM PRIORIDADE DEFINIDA:\n"
      no_priority.each { |task| message += format_task(task) }
      message += "\n"
    end

    # If no tasks in priority categories, show all tasks
    if high_priority.empty? && medium_priority.empty? && low_priority.empty? && no_priority.empty?
      message += "📋 TODAS AS TAREFAS:\n"
      @tasks.each { |task| message += format_task(task) }
      message += "\n"
    end

    if overdue_tasks.any?
      message += "⚠️ TAREFAS VENCIDAS: #{overdue_tasks.count}\n"
    end
    
    if upcoming_tasks.any?
      message += "⏰ TAREFAS PRÓXIMAS DO VENCIMENTO: #{upcoming_tasks.count}\n"
    end

    message += "\nTotal: #{@tasks.count} tarefas em #{boards.count} board(s)"
    
    # Add priority analysis for AI context
    message += "\n\nPara recomendações, considere:"
    message += "\n- Tarefas com alta prioridade são mais importantes"
    message += "\n- Tarefas vencidas precisam atenção imediata"
    message += "\n- Tarefas próximas do vencimento devem ser priorizadas"
    message += "\n- Tarefas sem prazo podem ser deixadas para depois"
    message += "\n\nIMPORTANTE: Sempre mencione as tarefas pelo nome exato que aparece entre aspas acima, nunca use 'tarefa 1', 'tarefa 2' ou termos genéricos."
    
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
        " (vence HOJE)"
      when 1
        " (vence AMANHÃ)"
      when -1
        " (venceu ONTEM)"
      when 2..7
        " (vence em #{days_diff} dias)"
      when -7..-1
        " (venceu há #{days_diff.abs} dias)"
      else
        " (vencimento: #{task.due_date.strftime('%d/%m/%Y')})"
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
        " (vence HOJE)"
      when 1
        " (vence AMANHÃ)"
      when -1
        " (venceu ONTEM)"
      when 2..7
        " (vence em #{days_diff} dias)"
      when -7..-1
        " (venceu há #{days_diff.abs} dias)"
      else
        " (vencimento: #{task.due_date.strftime('%d/%m/%Y')})"
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
    <<~PROMPT
      Você é um assistente de produtividade que analisa tarefas e cria resumos em texto simples.
      
      IMPORTANTE: Não use formatação markdown (**negrito**, *itálico*, etc). Use apenas texto simples.
      
      REGRA FUNDAMENTAL: SEMPRE mencione as tarefas pelo nome EXATO que aparece na lista. NUNCA use "tarefa 1", "tarefa 2" ou termos genéricos. Use o título real da tarefa entre aspas.
      
      Analise as tarefas fornecidas e crie um resumo seguindo EXATAMENTE esta estrutura:
      
      1. SITUAÇÃO GERAL: Mencione o total de tarefas e como estão distribuídas por prioridade
      2. URGÊNCIAS: Destaque tarefas vencidas ou próximas do vencimento usando seus nomes reais
      3. RECOMENDAÇÕES: Sugira especificamente quais tarefas fazer primeiro usando os nomes EXATOS das tarefas entre aspas. Explique o porquê de cada recomendação. Exemplo: Comece com "Nome da Tarefa Específica" porque está vencida há 2 dias.
      4. MOTIVAÇÃO: Termine com uma mensagem motivadora e realista
      
      Regras importantes:
      - Use apenas texto simples, sem formatação markdown
      - Seja conciso (máximo 4 parágrafos curtos)
      - Use emojis apenas no início de cada seção para destacar
      - SEMPRE cite o nome exato da tarefa entre aspas, nunca use "tarefa 1", "tarefa 2"
      - Explique sempre o motivo da recomendação (prazo, prioridade, dependência)
      - Mantenha um tom amigável e profissional
      
      Se não houver tarefas, encoraje o usuário a adicionar algumas ou parabenize se completou tudo.
    PROMPT
  end

  # Handles API errors and sets a flash message if a controller context is available.
  def handle_error(response)
    error_details = case response.code
    when 404
      "Modelo não encontrado ou indisponível"
    when 401
      "Token de autenticação inválido"
    when 429
      "Limite de requisições excedido"
    when 500, 502, 503
      "Erro interno do servidor OpenRouter"
    else
      response.message
    end
    
    error_message = "Erro ao gerar o resumo: #{error_details} (#{response.code})"
    
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