# frozen_string_literal: true

require 'sinatra'
require 'rack/auth/basic'

helpers do
  def protected!
    return if authorized?

    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    throw(:halt, [401, "Unauthorized access\nYou are denied access to this resource."])
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == %w[guest guest]
  end
end

get '/' do
  "I'm Feeling Grovery"
end

get '/cookie_renderer' do
  cookie_info = request.cookies.map.with_index(1) do |(name, value), i|
    "#{i}. #{name} #{value}"
  end.join(', ')

  "Request contained #{request.cookies.size} cookies: #{cookie_info}"
end

get '/auth' do
  protected!
  'Your browser made it!'
end

get '/headers' do
  headers_info =
    request.
    env.
    select { |k, _v| k.start_with?('HTTP_') }.
    map.with_index(1) do |(k, v), i|
      "#{i}. #{k.sub(/^HTTP_/, '').downcase.tr('_', '-')} #{v}"
    end.
    join(', ')

  "Request contained #{headers_info.count(', ') + 1} headers: #{headers_info}"
end

get '/cat' do
  '<html><body><img src="/cat.png" alt="Cat"></body></html>'
end
