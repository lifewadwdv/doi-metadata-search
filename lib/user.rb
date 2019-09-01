require 'sinatra/base'
require 'jwt'
require 'sinatra/json'

class User
  attr_accessor :name, :uid, :email, :jwt, :role_id, :orcid, :provider_id, :client_id, :beta_tester

  def initialize(cookie)
    token = ::JSON.parse(cookie).dig("authenticated", "access_token")
    return false unless token.present?

    payload = decode_token(token)

    @jwt = token
    @uid = payload.fetch("uid", nil)
    @name = payload.fetch("name", nil)
    @email = payload.fetch("email", nil)
    @role_id = payload.fetch("role_id", nil)
    @provider_id = payload.fetch("provider_id", nil)
    @client_id = payload.fetch("client_id", nil)
    @beta_tester = payload.fetch("beta_tester", false)
  end

  alias_method :orcid, :uid

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end

  # Helper method to check for personal account
  def is_person?
    uid.start_with?("0")
  end

  # encode token using SHA-256 hash algorithm
  def encode_token(payload)
    # replace newline characters with actual newlines
    private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
    JWT.encode(payload, private_key, 'RS256')
  end

  # decode token using SHA-256 hash algorithm
  def decode_token(token)
    public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    payload = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first

    # check whether token has expired
    return {} unless Time.now.to_i < payload["exp"]

    payload
  rescue JWT::DecodeError => error
    Rails.logger.error "JWT::DecodeError: " + error.message + " for " + token
    return {}
  rescue OpenSSL::PKey::RSAError => error
    public_key = ENV['JWT_PUBLIC_KEY'].presence || "nil"
    Rails.logger.error "OpenSSL::PKey::RSAError: " + error.message + " for " + public_key
    return {}
  end

  # encode token using SHA-256 hash algorithm
  def self.encode_token(payload)
    # replace newline characters with actual newlines
    private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
    JWT.encode(payload, private_key, 'RS256')
  end

  # generate JWT token
  def self.generate_token(attributes={})
    payload = {
      uid:  attributes.fetch(:uid, "0000-0001-5489-3594"),
      name: attributes.fetch(:name, "Josiah Carberry"),
      email: attributes.fetch(:email, nil),
      provider_id: attributes.fetch(:provider_id, nil),
      client_id: attributes.fetch(:client_id, nil),
      role_id: attributes.fetch(:role_id, "staff_admin"),
      iat: Time.now.to_i,
      exp: Time.now.to_i + attributes.fetch(:exp, 30)
    }.compact

    encode_token(payload)
  end
end
