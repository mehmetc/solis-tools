require 'active_support/all'
require 'sinatra/base'
require 'http/accept'
require 'solis'
require 'lib/file_queue'
require 'app/helpers/main_helper'

class GenericController < Sinatra::Base
    helpers Sinatra::MainHelper

  configure do
    mime_type :jsonapi, 'application/vnd.api+json'
    set :method_override, true # make a PUT, DELETE possible with the _method parameter
    set :show_exceptions, false
    set :raise_errors, false
    set :root, File.absolute_path("#{File.dirname(__FILE__)}/../../")
    set :views, (proc { "#{root}/app/views" })
    set :logging, true
    set :static, true
    set :public_folder, "#{root}/public"
    set :solis, Solis::Graph.new(Solis::Shape::Reader::File.read(solis_conf[:shape]), solis_conf)
  end

  get '/' do
    halt '404', 'To be implemented'
  end

  not_found do
    content_type :json
    message = body
    logger.error(message)
    message
  end

  error do
    content_type :json
    message = { status: 500, body: "error:  #{env['sinatra.error'].to_s}" }
    logger.error(message)
    message
  end
end