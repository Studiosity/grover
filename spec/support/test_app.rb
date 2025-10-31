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
  "<html><head><link rel='icon' href='data:;base64,iVBORw0KGgo='></head><body>I'm Feeling Grovery</body></html>"
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
  headers =
    request.
    env.
    select { |k, _v| k.start_with?('HTTP_') }
  headers_info =
    headers.
    map.with_index(1) { |(k, v), i| "#{i}. #{k.sub(/^HTTP_/, '').downcase.tr('_', '-')} #{v}" }.
    join(', ')

  "Request contained #{headers.size} headers: #{headers_info}"
end

get '/cat' do
  '<html><body><img src="/cat.png" alt="Cat"></body></html>'
end

get '/304' do
  redirect to('/cat.png'), 304
end
