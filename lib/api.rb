require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Api
    def get_works(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/works/#{params[:id]}?include=data-center,resource-type,work-type,member"
      else
        params = { id: params.fetch(:id, nil),
                   'page[number]': params.fetch('page[number]', 1),
                   'page[size]': params.fetch('page[size]', 25),
                   sort: params.fetch(:sort, nil),
                   query: params.fetch(:query, nil),
                   year: params.fetch('year', nil),
                   include: 'data-center,resource-type,work-type,member',
                   'resource-type-id' => params.fetch('resource-type-id', nil),
                   'relation-type-id' => params.fetch('relation-type-id', nil),
                   'data-center-id' => params.fetch('data-center-id', nil),
                   'member-id' => params.fetch('member-id', nil),
                   'work-id' => params.fetch('work-id', nil),
                   'person-id' => params.fetch('person-id', nil),
                   'source-id' => params.fetch('source-id', nil) }.compact

        url = "#{ENV['API_URL']}/works?" + URI.encode_www_form(params)
      end

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_people(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/people/" + params.fetch(:id)
      else
        params = { id: params.fetch(:id, nil),
                   'page[number]': params.fetch('page[number]', 1),
                   'page[size]': params.fetch('page[size]', 25),
                   query: params.fetch(:query, nil) }.compact
        url = "#{ENV['API_URL']}/people?" + URI.encode_www_form(params)
      end

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_datacenters(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/data-centers/#{params.fetch(:id)}?include=member"
      else
        params = { id: params.fetch(:id, nil),
                   ids: params.fetch(:ids, nil),
                   'page[number]': params.fetch('page[number]', 1),
                   'page[size]': params.fetch('page[size]', 25),
                   query: params.fetch(:query, nil),
                   year: params.fetch(:year, nil),
                   include: 'member',
                   "member-id" => params.fetch("member-id", nil),
                   "registration-agency-id" => "datacite" }.compact
        url = "#{ENV['API_URL']}/data-centers?" + URI.encode_www_form(params)
      end

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_members(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/members/#{params.fetch(:id)}"
      else
        params = { id: params.fetch(:id, nil),
                   'member-type' => params.fetch('member-type', nil),
                   region: params.fetch(:region, nil),
                   year: params.fetch(:year, nil),
                   query: params.fetch(:query, nil) }.compact
        url = "#{ENV['API_URL']}/members?" + URI.encode_www_form(params)
      end

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end
  end

  helpers Api
end
