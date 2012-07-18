require 'sinatra'
require 'sinatra/content_for'
require 'sass'
require 'json'

configure do
  enable :sessions

  set :cfg_path, File.join(File.dirname(__FILE__), "config.json")
  @@settings = JSON.parse(File.read(settings.cfg_path))
end

before do
  if !@@settings then
    @@settings = JSON.parse(File.read(settings.cfg_path))
  end

  @settings = @@settings
end

get '/css/:sheet.css' do |sheet|
  content_type 'text/css', :charset => 'utf-8'
  scss :"#{sheet}", :views => './public/css'
end

get '/skins/:skin' do |skin|
  session[:skin] = skin
  redirect back
end

get '/settings' do
  erb :settings
end
post '/settings' do
  File.open(settings.cfg_path, "w") { |f|
    f.write(params.to_json)
  }

  erb :settings
end

get '/' do
  erb :index  
end

get '/:group/:klass/:view' do |*args|
  @group, @klass, @view = args

  erb :view
end

get '/:group/:klass' do |group, klass|
  @group, @klass = group, klass

  erb :klass
end


get '/:group' do |group|
  puts "in /:group with group: #{group}"
  @group = group
  erb :group
end

helpers do
  def skin
    session[:skin] || "minimal"
  end
end