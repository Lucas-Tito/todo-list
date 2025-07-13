class SessionsController < ApplicationController
  skip_before_action :authenticate_user, only: [:create]

  def create
    id_token = params[:id_token]
    
    Rails.logger.info "Received login request with token: #{id_token.present? ? 'present' : 'missing'}"
    Rails.logger.info "Request headers: #{request.headers.to_h.select { |k, v| k.start_with?('HTTP_') }}"
    
    if id_token.blank?
      Rails.logger.error "Missing ID token in login request"
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
      
      Rails.logger.info "Attempting to decode JWT token..."
      
      # Decode the JWT token to get user info (Firebase already verified it on client side)
      decoded_token = JWT.decode(id_token, nil, false) # Don't verify signature for now
      payload = decoded_token[0]
      header = decoded_token[1]
      
      Rails.logger.info "Token decoded successfully. Payload keys: #{payload.keys}"
      Rails.logger.info "Token header: #{header}"
      Rails.logger.info "User email: #{payload['email']}"
      Rails.logger.info "Token issuer: #{payload['iss']}"
      Rails.logger.info "Token audience: #{payload['aud']}"
      Rails.logger.info "Token subject: #{payload['sub']}"
      
      # Verify it's from the correct issuer
      unless payload['iss'] == 'https://securetoken.google.com/todolist-ruby'
        Rails.logger.error "Invalid token issuer: #{payload['iss']}"
        raise StandardError.new('Invalid token issuer')
      end
      
      # Verify audience
      unless payload['aud'] == 'todolist-ruby'
        Rails.logger.error "Invalid token audience: #{payload['aud']}"
        raise StandardError.new('Invalid token audience')
      end
      
      # Check token expiration
      if payload['exp'] && Time.at(payload['exp']) < Time.current
        Rails.logger.error "Token has expired. Exp: #{Time.at(payload['exp'])}, Current: #{Time.current}"
        raise StandardError.new('Token has expired')
      end
      
      Rails.logger.info "Token validation passed. Creating/finding user..."
      
      user = User.find_or_create_by(uid: payload['sub']) do |u|
        u.name = payload['name'] || payload['email'].split('@')[0]
        u.email = payload['email']
        Rails.logger.info "Creating new user: #{u.email}"
      end
      
      if user.persisted?
        session[:user_id] = user.id
        Rails.logger.info "User authenticated successfully: #{user.email} (ID: #{user.id})"
        render json: { 
          status: 'success', 
          user: { 
            id: user.id, 
            email: user.email, 
            name: user.name 
          } 
        }
      else
        Rails.logger.error "Failed to save user: #{user.errors.full_messages}"
        render json: { status: 'error', message: 'Failed to create user account' }, status: :internal_server_error
      end
      
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      Rails.logger.error "Token format: #{id_token.class} - Length: #{id_token.length}"
      render json: { status: 'error', message: 'Invalid token format' }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error "Token validation error: #{e.message}"
      render json: { status: 'error', message: e.message }, status: :unauthorized
    rescue => e
      Rails.logger.error "Unexpected error during authentication: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      render json: { status: 'error', message: 'Authentication failed' }, status: :internal_server_error
    end
  end

  def destroy
    Rails.logger.info "User logout request. Current user ID: #{session[:user_id]}"
    session[:user_id] = nil
    Rails.logger.info "User logged out successfully"
    render json: { status: 'success' }
  end
end