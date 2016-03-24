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
      return client.login params[:user]
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
        requires :mail, type: String
        requires :password, type: String
        requires :lang, type: String
      end
    end
    post '/register' do
      client = Users.new
      return client.newUser params[:user]
    end
    
    params do
      requires :mail, type: String
    end
    post '/reqreset' do
      client = Users.new
      return client.requestReset params[:mail]
    end

    params do
      requires :mail, type: String
      requires :token, type: String
      requires :action, type: String
    end
    get '/verify' do
      client = Users.new
      case params[:action]
      when 'verify'
        resp = client.setVerified params[:mail], params[:token]
      when 'reset'
        resp = client.resetPassword params[:mail], params[:token]
      end
    end
    
    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :token, type: String
        requires :password, type: String
      end
    end
    delete '/delete' do
      client = Users.new
      return client.delUser params[:user]
    end
    
  end
end
