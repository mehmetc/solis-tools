# frozen_string_literal: true
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

  get '/_help/?' do
    content_type :html
    redirect "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}_help/index.html"
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_vandal/?' do
    content_type :html
    erb :'vandal/index.html', locals: { base_path: "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}", vandal_path: "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}_vandal/" }
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_doc/?' do
    content_type :html
    erb :'doc/index.html', locals: { base_path: "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}" }
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  end

  get '/_yas/?' do
    content_type :html
    erb :'yas/index.html', locals: { sparql_endpoint: "#{Solis::ConfigFile[:services][$SERVICE_ROLE][:base_path]}_sparql" }
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

    if params.key?('query')
      query = params['query']
      data = "query=#{URI.encode_uri_component(query)}"
    else
      data = request.body.read
    end

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

  get '/_model' do
    timing_start = Time.now
    content_type @media_type

    prefix = params[:prefix] || solis_conf[:graphs].select{|s| s['type'].eql?(:main)}.first['prefix'] rescue 'solis'

      begin
        raise "Please generate model first" unless File.exist?("#{Solis::ConfigFile.path}/solis/#{prefix}.puml")
        puml = File.read("#{Solis::ConfigFile.path}/solis/#{prefix}.puml").gsub('!pragma layout elk','')
        File.open("#{Solis::ConfigFile.path}/solis/#{prefix}.url", 'wb') { |f| f.puts PlantUML.url_for_uml(puml) }
      rescue StandardError => e
        puts e.message
        raise "Error loading model"
      end

    case @media_type
    when 'application/shacl'
      File.read("#{Solis::ConfigFile.path}/solis/#{prefix}_shacl.ttl")
    when "application/owl"
      content_type "application/owl+xml"
      File.read("#{Solis::ConfigFile.path}/solis/#{prefix}_schema.ttl")
    when "application/puml"
      File.read("#{Solis::ConfigFile.path}/solis/#{prefix}.puml")
    when "image/svg"
      content_type "image/svg+xml"
      File.read("#{Solis::ConfigFile.path}/solis/#{prefix}.svg")
    when "image/png"
      File.read("#{Solis::ConfigFile.path}/solis/#{prefix}.png")
    else
      redirect_url = File.read("#{Solis::ConfigFile.path}/solis/#{prefix}.url").gsub(/[\000-\037]/, '')
      redirect redirect_url
    end
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  get '/_model/:job_id' do
    content_type :json
    timing_start = Time.now
    job_id = params[:job_id]
    progress = settings.progress_store[job_id] || 100
    {progress: progress}.to_json
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

  post '/_model' do
    job_id = SecureRandom.uuid
    settings.progress_store[job_id] = 0  # Initialize progress

    timing_start = Time.now

    prefix = params[:prefix] || solis_conf[:graphs].select{|s| s['type'].eql?(:main)}.first['prefix'] rescue 'solis'
    sheet_id = params[:sheet] || Solis::ConfigFile[:sheets][prefix.to_sym]
    google_key = params[:key] || Solis::ConfigFile[:key] || nil

    raise RuntimeError, "Missing Google API key" unless google_key

    Thread.new do
      build_model_by_sheet_id(job_id,
                              google_key,
                              sheet_id,
                              prefix,
                              params.key?(:from_cache) ? params[:from_cache] == 1 : false)
      Solis::LOGGER.info('done')
    end

    job_id
  rescue StandardError => e
    halt 500, api_error('500', request.url, 'Unknown Error', e.message, e)
  ensure
    headers 'X-TIMING' => (((Time.now - timing_start) * 1000).to_i).to_s
  end

end
