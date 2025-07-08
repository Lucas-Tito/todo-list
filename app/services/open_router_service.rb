# Service to interact with the OpenRouter API for generating task summaries.
class OpenRouterService
  # Base URI for the OpenRouter API.
  include HTTParty
  base_uri "https://openrouter.ai/api/v1"

  # Initializes the service with tasks and an optional controller context.
  # @param tasks [ActiveRecord::Relation] the tasks to be summarized.
  # @param controller [ApplicationController] the controller instance, used for flash messages.
  def initialize(tasks, controller = nil)
    @tasks = tasks
    @controller = controller
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

    # Makes a POST request to the OpenRouter API with the prepared body.
    response = self.class.post("/chat/completions", @options.merge(body: body.to_json))

    # Handles successful and unsuccessful API responses.
    if response.success?
      response.dig("choices", 0, "message", "content")
    else
      handle_error(response)
    end
  rescue StandardError => e
    # Rescues from standard errors (e.g., network issues) and returns an error message.
    "Ocorreu um erro ao conectar com a OpenRouter API: #{e.message}"
  end

  private

  # Prepares the request body for the OpenRouter API.
  def body
    {
      model: "mistralai/mistral-7b-instruct:free",
      messages: [
        { role: "system", content: system_message },
        { role: "user", content: user_message }
      ]
    }
  end

  # Creates a detailed user message with the list of tasks.
  def user_message
    tasks_string = @tasks.map do |task|
      "- #{task.title} (Prioridade: #{task.priority || 'não definida'}, Vencimento: #{task.due_date || 'não definido'})"
    end.join("\n")

    "Aqui estão as minhas tarefas:\n#{tasks_string}"
  end

  # Defines the system message to guide the AI's response.
  def system_message
    "Você é um assistente de produtividade. Resuma as seguintes tarefas em um parágrafo conciso, destacando as mais urgentes e importantes. Forneça um resumo amigável e motivador."
  end

  # Handles API errors and sets a flash message if a controller context is available.
  def handle_error(response)
    error_message = "Erro ao gerar o resumo: #{response.code} - #{response.message}"
    
    # Sets a flash alert if a controller is present.
    if @controller
      @controller.flash.now[:alert] = error_message
    end
    
    error_message
  end
end