require_relative 'users'

class Login < Grape::API
  format :json
  prefix :api

  resource 'users' do
    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :password, type: String
        requires :defLang, type: String
      end
    end
    post '/login' do
      client = Users.new params[:user][:defLang]
      return client.login params[:user]
    end

    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :token, type: String
        requires :defLang, type: String
      end
    end    
    post '/logout' do
      client = Users.new params[:user][:defLang]
      client.logout params[:user]
    end

    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :password, type: String
        requires :defLang, type: String
      end
    end
    post '/register' do
      client = Users.new params[:user][:defLang]
      return client.newUser params[:user]
    end
    
    params do
      requires :mail, type: String
      requires :defLang, type: String
    end
    post '/reqreset' do
      client = Users.new params[:defLang]
      return client.requestReset params[:mail]
    end

    params do
      requires :mail, type: String
      requires :token, type: String
      requires :action, type: String
      requires :defLang, type: String
    end
    get '/verify' do
      client = Users.new params[:defLang]
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
        requires :defLang, type: String
      end
    end
    delete '/delete' do
      client = Users.new params[:user][:defLang]
      return client.delUser params[:user]
    end
    
    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :token, type: String
        requires :password, type: String
        requires :defLang, type: String        
      end
    end
    post '/update' do
      client = Users.new params[:user][:defLang]
      return client.updateUser params[:user]
    end
    
    params do
      requires :mail, type: String
      requires :token, type: String
      requires :defLang, type: String
    end
    post '/getData' do
      client = Users.new params[:defLang]
      return client.getData params[:mail], params[:token]
    end
    
    params do
      requires :mail, type: String
      requires :token, type: String
      requires :defLang, type: String 
    end
    post '/allUsers' do
      client = Users.new params[:defLang]
      return client.getAllUsers params[:mail], params[:token]
    end       
    
  end
end
