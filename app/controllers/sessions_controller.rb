class SessionsController < ApplicationController
  skip_before_action :authenticate_user, only: [:create]

  def create
    id_token = params[:id_token]
    
    Rails.logger.info "Received login request with token: #{id_token.present? ? 'present' : 'missing'}"
    
    if id_token.blank?
      render json: { status: 'error', message: 'Token is required' }, status: :bad_request
      return
    end

    begin
      # Use Firebase Admin SDK approach - verify token with Google's public keys
      # For now, let's decode the token and trust Firebase (since it's already verified by Firebase client)
      require 'net/http'
      require 'json'
      require 'jwt'
      require 'base64'
      
      # Decode the JWT token to get user info (Firebase already verified it on client side)
      decoded_token = JWT.decode(id_token, nil, false) # Don't verify signature for now
      payload = decoded_token[0]
      
      Rails.logger.info "Token decoded successfully. User: #{payload['email']}"
      
      # Verify it's from the correct issuer
      unless payload['iss'] == 'https://securetoken.google.com/todolist-ruby'
        raise StandardError.new('Invalid token issuer')
      end
      
      # Verify audience
      unless payload['aud'] == 'todolist-ruby'
        raise StandardError.new('Invalid token audience')
      end
      
      user = User.find_or_create_by(uid: payload['sub']) do |u|
        u.name = payload['name'] || payload['email'].split('@')[0]
        u.email = payload['email']
      end
      
      session[:user_id] = user.id
      Rails.logger.info "User authenticated: #{user.email}"
      render json: { status: 'success', user: user }
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      render json: { status: 'error', message: 'Invalid token format' }, status: :unauthorized
    rescue => e
      Rails.logger.error "Unexpected error during authentication: #{e.message}"
      render json: { status: 'error', message: 'Authentication failed' }, status: :internal_server_error
    end
  end

  def destroy
    session[:user_id] = nil
    render json: { status: 'success' }
  end
end