require 'sinatra'
require 'oj'
require 'ipaddr'
require_relative 'config/environment'
require_relative 'config/initializers'

class IpMonitoringApp < Sinatra::Base
  set :port, ENV['PORT'] || 4567
  set :show_exceptions, false

  $start_time = Time.zone.now

  before do
    content_type :json
  end

  post '/ips' do
    response = RequestHandler.handle_post_ips(request.body.read)
    status response[:status]
    response[:body]
  end

  get '/ips' do
    response = RequestHandler.handle_get_ips
    status response[:status]
    response[:body]
  end

  get '/ips/:id' do
    response = RequestHandler.handle_get_ip(params[:id])
    status response[:status]
    response[:body]
  end

  delete '/ips/:id' do
    response = RequestHandler.handle_delete_ip(params[:id])
    status response[:status]
    response[:body]
  end

  post '/ips/:id/enable' do
    response = RequestHandler.handle_enable_ip(params[:id])
    status response[:status]
    response[:body]
  end

  post '/ips/:id/disable' do
    response = RequestHandler.handle_disable_ip(params[:id])
    status response[:status]
    response[:body]
  end

  get '/ips/:id/stats' do
    response = RequestHandler.handle_ip_stats(
      params[:id],
      params[:time_from],
      params[:time_to]
    )
    status response[:status]
    response[:body]
  end

  get '/health' do
    response = RequestHandler.handle_health_check
    status response[:status]
    response[:body]
  end

  get '/' do
    erb :index
  end

  error do
    status 422
    Oj.dump({ error: 'Something went wrong' })
  end
end

IpAddress.create_table
PingResult.create_table
Scheduler.start
