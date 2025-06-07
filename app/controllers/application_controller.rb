class ApplicationController < ActionController::Base
  # Inclui o módulo RecordIdentifier para ter acesso ao helper dom_id
  include ActionView::RecordIdentifier

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end