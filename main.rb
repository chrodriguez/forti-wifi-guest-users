Bundler.require
require 'logger'
require 'sinatra/config_file'

set :local_config, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'app.yml'))
set :logger, Logger.new(STDOUT)

settings.logger.info "Loading config file from #{settings.local_config}"

config_file settings.local_config

before do
  begin
    raise 'url must be set in config' if settings.url.empty?
    raise 'user must be set in config' if settings.user.empty?
    raise 'password must be set in config' if settings.password.empty?
    raise 'ttl must be set in config' unless settings.ttl
  rescue NoMethodError 
    puts 'Check if you set url, user, password and ttl in config file'
    return 500
  end
end

post '/get_guest_user' do
  name = params[:name]
  return 404 unless name
  create_forti_user name
end

delete '/purge' do
  purge
  200
end

def connection
  @connection ||= Faraday.new(:url => settings.url) do |faraday|
    faraday.request   :url_encoded             # form-encode POST params
    faraday.response  :logger                  # log requests to STDOUT
    faraday.use       :cookie_jar
    faraday.adapter   Faraday.default_adapter  # make requests with Net::HTTP
    faraday.ssl.verify = false
  end
end

private

def forti_login
  response = connection.post '/logincheck', {ajax: 1, username: settings.user, secretkey: settings.password}
  raise 'Login error' unless response.status == 200
end

def forti_post_user(name)
  # Try setting cookie
  response = connection.get '/p/user/guest/edit/WiFI_Invitados/'
  raise 'Error setting required cookies' unless response.status == 200

  # Read cookie for post
  csrf_match = response['set-cookie'].match(/csrftoken=(\w+);.*/)
  raise 'required cookie not found' unless csrf_match
  csrf = csrf_match[1]

  # Try post data
  response = connection.post "/p/user/guest/edit/WiFI_Invitados/", {csrfmiddlewaretoken: csrf, group: 'WiFI_Invitados', user_name: name, expire: get_ttl}, referer: "#{settings.url}/p/user/guest/edit/WiFI_Invitados/"
  raise 'Post must redirect with 302' unless response.status == 302
  location =  response.headers['location']

  # Follow 302 after post with get
  response = connection.get location
  raise 'Error reading user data' unless response.status == 200
  response.body
end

def purge
  forti_login
  response = connection.get '/p/user/guest/purge/WiFI_Invitados/'
  raise 'Error purging' unless response.status == 302
end

def create_forti_user(name)
  forti_login
  data = forti_post_user name
  user = data.match(%r{<td><label>User ID</label></td><td>(.*)</td>})[1]
  password = data.match(%r{<td><label>Password</label></td><td>(.*)</td>})[1]
  return %Q/{ "user": "#{user}", "password": "#{password}"}\n/
rescue Exception => e
  puts e.message
  500
end

def get_ttl
  if settings.ttl_from_now
    (Time.now + settings.ttl).strftime "%Y-%m-%d %H:%M"
  else
    settings.ttl
  end
end
