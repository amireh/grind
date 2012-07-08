require 'sinatra'
require 'sinatra/content_for'

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

