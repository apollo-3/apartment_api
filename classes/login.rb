require_relative 'users'

class Login < Grape::API
  format :json
  prefix :api

  resource 'users' do
    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :password, type: String
      end
    end
    post '/login' do
      client = Users.new
      return client.checkUser params[:user]
    end

    get '/logout' do
      return "{'success':'ok'}"
    end
  end
end
