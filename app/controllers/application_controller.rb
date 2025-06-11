class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier
  allow_browser versions: :modern

  # This action will run before any other action in your application.
  before_action :set_current_board

  private

  # This method sets the currently active board.
  def set_current_board
    # Use the board_id from the URL parameters if present.
    if params[:board_id]
      @current_board = Board.find(params[:board_id])
      session[:board_id] = @current_board.id
    # Otherwise, use the board_id from the session.
    elsif session[:board_id]
      @current_board = Board.find_by(id: session[:board_id])
    end

    # If no board is found, create a default one to ensure the app always has a board.
    if @current_board.nil?
      @current_board = Board.first_or_create!(name: "Meu Primeiro Board")
      session[:board_id] = @current_board.id
    end
  end
end