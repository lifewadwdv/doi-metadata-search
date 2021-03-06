# # load ENV variables from .env file if it exists
env_file =  File.expand_path("../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

require 'securerandom'
require 'active_support/all'
require "benchmark"

# required ENV variables, can be set in .env file
ENV['APPLICATION'] ||= "doi-metadata-search"
ENV['SECRET_KEY_BASE'] ||= SecureRandom.hex(15)
ENV['SITE_TITLE'] ||= "DataCite Search"
ENV['LOG_LEVEL'] ||= "info"
ENV['RA'] ||= "datacite"
ENV['TRUSTED_IP'] ||= "172.0.0.0/8"
ENV['JWT_HOST'] ||= "https://profiles.stage.datacite.org"
ENV['API_URL'] ||= "https://api.test.datacite.org"
ENV['ORCID_UPDATE_URL'] ||= "https://api.stage.datacite.org"
ENV['VOLPINO_URL'] ||= "https://api.stage.datacite.org"
ENV['FABRICA_URL'] ||= "https://doi.stage.datacite.org"
ENV['DATA_URL'] ||= "https://api.stage.datacite.org"
ENV['HOMEPAGE_URL'] ||= "https://www.stage.datacite.org"
ENV['COMMONS_URL'] ||= "https://commons.stage.datacite.org"
ENV['CDN_URL'] ||= "https://www.stage.datacite.org"
ENV['SITEMAPS_URL'] ||= "https://search.stage.datacite.org"

env_vars = %w(SITE_TITLE LOG_LEVEL RA API_URL SECRET_KEY_BASE)
env_vars.each { |env| fail ArgumentError,  "ENV[#{env}] is not set" unless ENV[env].present? }

# Constants
MIN_MATCH_SCORE = 2
MIN_MATCH_TERMS = 3
MAX_MATCH_TEXTS = 1000
TYPICAL_ROWS = [10, 20, 50, 100, 500]
DEFAULT_ROWS = 25
MONTH_SHORT_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
ORCID_VERSION = '1.2'
TIMEOUT = 30

require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'sinatra/cookies'
require 'logger'
require 'logstash-logger'
require 'tilt/haml'
require 'haml'
require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate-bootstrap'
require 'cgi'
require 'maremma'
require 'gabba'
require 'rack-flash'
require 'jwt'
require 'open-uri'
require 'uri'
require 'better_errors'
require 'gon-sinatra'
require 'git'
require 'rack/crawler_detect'


Sinatra::register Gon::Sinatra
register Gon::Sinatra

Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

configure do
  set :root, File.dirname(__FILE__)

  # Configure sessions and flash
  use Rack::Session::Cookie, secret: ENV['SECRET_KEY_BASE']
  use Rack::Flash

  use Rack::CrawlerDetect

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Enable logging
  enable :logging
  # use Rack::CommonLogger, LogStashLogger.new(type: :stdout)

  # Set facet fields
  set :facet_fields, %w(resourceType_facet publicationYear datacentre_facet rightsURI)

  # Google analytics event tracking
  set :ga, Gabba::Gabba.new(ENV['GABBA_COOKIE'], ENV['GABBA_URL']) if ENV['GABBA_COOKIE']

  # fetch version and revision from git
  g = Git.open(Sinatra::Application.root)
  begin
    set :version, g.tags.map { |t| Gem::Version.new(t.name) }.sort.last.to_s
  rescue ArgumentError
    set :version, "1.0"
  end
  set :revision, g.object('HEAD').sha

  # use Sentry for error tracking
  if ENV['SENTRY_DSN']
    require 'raven'

    Raven.configure do |config|
      config.dsn = ENV['SENTRY_DSN']
      config.release = "doi-metadata-search:" + Sinatra::Application.version
    end

    use Raven::Rack
    enable :raise_errors
  end
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP']
  BetterErrors.application_root = File.expand_path('..', __FILE__)

  enable :raise_errors, :dump_errors
  # disable :show_exceptions
end

before do
  page = params[:page].is_a?(String) ? params[:page].to_i : 1
  @page = page < 1 ? 1 : page
  @meta = {}
end

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/' do
  @meta = { page: "splash" }

  haml :splash
end

get '/works' do
  @works = get_works(query: params[:query], 'page[number]' => @page, 'data-center-id' => params['data-center-id'], 'resource-type-id' => params['resource-type-id'], 'year' => params['year'], 'registered' => params['registered'], 'affiliation-id' => params['affiliation-id'], 'has-views' => params['has-views'], 'has-downloads' => params['has-downloads'], 'has-citations' => params['has-citations'])
  
  # check for existing claims if user is logged in and is person
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user && is_person?

  # pagination
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "works"
  haml :'works/index'
end

get %r{/works/(.+)} do
  params["id"] = params[:captures].first

  # workaround, as nginx swallows double backslashes
  params["id"] = params["id"].gsub(/(http|https):\/+(\w+)/, '\1://\2')

  @work = get_works(id: params["id"])
  halt 404 if @work[:errors].present?

  doi = validate_doi(params[:id])
  link = doi ? "https://doi.org/#{doi}" : params[:id]

  # check for existing claims if user is logged in and work is registered with DataCite
  if current_user
    @work[:data] = get_claimed_items(current_user, [@work[:data]]).first
  end

  # embed schema.org
  response = Maremma.get("#{ENV['API_URL']}/dois/#{params[:id]}", headers: {"Accept"=> "application/ld+json"}, raw: true, timeout: TIMEOUT)
  @work[:schema_org] = response.body.fetch("data", nil)

  params[:model] = "works"

  headers['Link'] = "<#{link}> ; rel=\"identifier\", " +
                    "<#{link}> ; rel=\"describedby\" ; type=\"application/vnd.datacite.datacite+xml\", " +
                    "<#{link}> ; rel=\"describedby\" ; type=\"application/vnd.citationstyles.csl+json\", " +
                    "<#{link}> ; rel=\"describedby\" ; type=\"application/x-bibtex\""
  haml :'works/show'
end

get '/people' do
  @people = get_people(query: params[:query], 'page[number]' => @page)

  # pagination
  @people[:data] = pagination_helper(@people[:data], @page, @people.fetch(:meta, {}).fetch("total", 0))

  haml :'people/index'
end

get '/people/:id' do
  @person = get_people(id: params[:id])

  if !validate_orcid(params[:id])
    @works = { data: [] }
  elsif @person[:errors].present?
    link = "https://orcid.org/#{params[:id]}"
    headers['Link'] = "<#{link}> ; rel=\"identifier\""

    @person = { data: { "id" => link, "attributes" => { "orcid" => params[:id] } },
                errors: [{ "status" => "400", "title" => "The owner of this ORCID ID has not registered with DataCite, or has not made their record public." }] }
    @works = { data: [] }
  else
    link = "https://orcid.org/#{params[:id]}"
    headers['Link'] = "<#{link}> ; rel=\"identifier\""

    @works = get_works(query: params[:query], "user-id" => params[:id], 'page[number]' => @page, 'client-id' => params['data-center-id'], 'resource-type-id' => params['resource-type-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], 'registered' => params['registered'], 'affiliation-id' => params['affiliation-id'], sort: params[:sort])

    # check for existing claims if user is logged in and has personal account
    @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user && is_person?
  end

  # pagination for works
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "people"

  haml :'people/show'
end

get '/repositories' do
  @datacenters  = get_datacenters(query: params[:query], 'page[number]' => @page, "registration-agency-id" => params["registration-agency-id"], "member-id" => params["member-id"], year: params["year"])

  # pagination
  @datacenters[:data] = pagination_helper(@datacenters[:data], @page, @datacenters.fetch(:meta, {}).fetch("total", 0))

  haml :'repositories/index'
end

get '/repositories/:id' do
  @datacenter = get_datacenters(id: params[:id])

  @works = get_works(query: params[:query], "data-center-id" => params[:id], 'page[number]' => @page, 'resource-type-id' => params['resource-type-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], 'registered' => params['registered'], 'affiliation-id' => params['affiliation-id'], sort: params[:sort])

  # check for existing claims if user is logged in and has personal account
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user && is_person?

  # pagination for works
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "repositories"
  haml :'repositories/show'
end

get '/members' do
  @members = get_members(query: params[:query], "member-type" => params["member-type"], region: params[:region], year: params[:year])

  haml :'members/index'
end

get '/members/:id' do
  @member = get_members(id: params[:id])

  @works = get_works(query: params[:query], "member-id" => params[:id], 'page[number]' => @page, 'resource-type-id' => params['resource-type-id'], 'data-center-id' => params['data-center-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], 'registered' => params['registered'], 'affiliation-id' => params['affiliation-id'])

  # check for existing claims if user is logged in
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user

  # pagination for works
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "members"
  haml :'members/show'
end

get '/heartbeat' do
  content_type 'text/html'

  'OK'
end
