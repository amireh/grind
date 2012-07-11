require 'sinatra'
require 'sinatra/content_for'
require 'sass'

configure do
  enable :sessions
end

get '/css/:sheet.css' do |sheet|
  content_type 'text/css', :charset => 'utf-8'
  scss :"#{sheet}", :views => './public/css'
end

get '/skins/:skin' do |skin|
  session[:skin] = skin
  redirect back
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