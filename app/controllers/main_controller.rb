# frozen_string_literal: true
require 'http'
require_relative 'generic_controller'

class MainController < GenericController
  get '/' do
    content_type :json
    endpoints(solis_conf[:base_path]).to_json
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end
  get '/_formats' do
    content_type :json
    formats.to_json
  end

  get '/_vandal/?' do
    #File.read('public/vandal/index.html')
    redirect to('/_vandal/index.html')
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_doc/?' do
    redirect to('/_doc/index.html')
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_yas/?' do
    erb :'yas/index.html', locals: { sparql_endpoint: '/_sparql' }
    #redirect to('/_yas/index.html')
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_sparql/?' do
    content_type :json
    halt 501, api_error('501', request.url, 'SparQL error', 'Only POST queries are supported')
  end

  post '/_sparql' do
    timing_start = Time.now
    content_type env['HTTP_ACCEPT'] || 'text/turtle'
    result = ''
    data = request.body.read

    halt 501, api_error('501', request.url, 'SparQL error', 'INSERT, UPDATE, DELETE not allowed') unless data.match(/clear|drop|insert|update|delete/i).nil?
    data = URI.decode_www_form(data).to_h

    url = "#{solis_conf[:sparql_endpoint]}"

    response = HTTP.post(url, form: data, headers: {'Accept' => env['HTTP_ACCEPT'] || 'text/turtle'})
    if response.status == 200
      result = response.body.to_s
    elsif response.status == 500
      halt 500, api_error('500', request.url, 'SparQL error', response.body.to_s)
    elsif response.status == 400
      halt 400, api_error('400', request.url, 'SparQL error', response.body.to_s)
    else
      halt response.status, api_error(response.status.to_s, request.url, 'SparQL error', response.body.to_s)
    end

    result
  rescue HTTP::Error => e
    halt 500, api_error('500', request.url, 'SparQL error', e.message, e)
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'SparQL error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  get '/schema.json' do
    timing_start = Time.now
    content_type :json
    Graphiti::Schema.generate.to_json
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end
end
