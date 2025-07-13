class SessionsController < ApplicationController
  skip_before_action :authenticate_user, only: [:create]

  def create
    id_token = params[:id_token]
    validator = GoogleIDToken::Validator.new
    begin
      payload = validator.check(id_token, ENV['FIREBASE_PROJECT_ID'])
      user = User.find_or_create_by(uid: payload['sub']) do |u|
        u.name = payload['name']
        u.email = payload['email']
      end
      session[:user_id] = user.id
      render json: { status: 'success', user: user }
    rescue GoogleIDToken::ValidationError => e
      render json: { status: 'error', message: e.message }, status: :unauthorized
    end
  end

  def destroy
    session[:user_id] = nil
    render json: { status: 'success' }
  end
end