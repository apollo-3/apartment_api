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
      status 200
      client = Users.new
      return client.checkUser params[:user]
    end

    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :token, type: String
      end
    end    
    post '/logout' do
      client = Users.new
      client.logout params[:user]
    end

    params do
      requires :user, type: Hash do
        requires :name, type: String
        requires :mail, type: String
        requires :password, type: String
      end
    end
    post '/register' do
      client = Users.new
      return client.newUser params[:user]
    end

    params do
      requires :mail, type: String
      requires :token, type: String
    end
    get '/verify' do
      client = Users.new
      return client.setVerified params[:mail], params[:token]
    end
  end
end
