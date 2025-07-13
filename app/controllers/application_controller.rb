class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier
  allow_browser versions: :modern

  # This action will run before any other action in your application.
  before_action :set_locale
  # Auth happens before loading board.
  before_action :authenticate_user
  before_action :set_current_board

  private

  # Define language based on browser language
  def set_locale
    I18n.locale = extract_locale_from_accept_language_header || I18n.default_locale
  end

  # Try to extracts the first two characteres from browser language
  def extract_locale_from_accept_language_header
    return unless request.env['HTTP_ACCEPT_LANGUAGE']

    browser_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    I18n.available_locales.map(&:to_s).include?(browser_locale) ? browser_locale : nil
  end

  # This method sets the currently active board.
  def set_current_board
    if current_user
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

  def authenticate_user
    redirect_to root_path unless current_user
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

end