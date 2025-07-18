class PagesController < ApplicationController
  # Skip the user verification for the login page.
  # you can't ask for the user to already be authenticated on the login page.
  skip_before_action :authenticate_user, only: [:login]
  
  # Redirect to main page if user is already authenticated.
  before_action :redirect_if_authenticated, only: [:login]

  def login
    # Renders login view.
  end

  private

  def redirect_if_authenticated
    redirect_to app_root_path if current_user
  end
end