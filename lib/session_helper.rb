require 'sinatra/base'

module Sinatra
  module SessionHelper
    def current_user
      @current_user ||= cookies[:jwt].present? ? User.new((JWT.decode cookies[:jwt], ENV['JWT_SECRET_KEY']).first) : nil
    end

    def user_signed_in?
      !!current_user
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end
  end

  helpers SessionHelper
end
