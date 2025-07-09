class AisController < ApplicationController
  # The 'show' action now prepares the data for the selection page.
  # It fetches all boards and makes them available to the view.
  def show
    @boards = Board.order(:name)
  end

  # The 'create' action now handles the form submission from the 'show' page.
  def create
    # Retrieves the selected board IDs from the form parameters.
    board_ids = params[:board_ids]

    # Provides feedback if no boards were selected.
    if board_ids.blank?
      @summary = "Por favor, selecione ao menos um board para gerar o resumo."
    else
      # Fetches all uncompleted tasks from the lists belonging to the selected boards.
      tasks = Task.joins(:list).where(lists: { board_id: board_ids }).uncompleted.order(:created_at)
      
      # Calls the OpenRouterService with the collected tasks.
      @summary = OpenRouterService.new(tasks, self).call
    end
    
    # Responds with a Turbo Stream to update the summary response area on the same page.
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("summary_response", partial: "ais/summary_response", locals: { summary: @summary })
      end
    end
  end
end