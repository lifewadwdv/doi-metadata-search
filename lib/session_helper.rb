require 'sinatra/base'
require 'sinatra/json'

module Sinatra
  module SessionHelper
    def current_user
      @current_user ||= cookies[:_datacite].present? && ::JSON.parse(cookies[:_datacite]).dig("authenticated", "access_token").present? ? User.new(cookies[:_datacite]) : nil
    end

    def user_signed_in?
      !!current_user
    end

    def is_person?
      current_user && current_user.is_person?
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end
  end

  helpers SessionHelper
end
