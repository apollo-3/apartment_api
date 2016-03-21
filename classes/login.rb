require_relative 'mymongo'

class Login < Grape::API
  format :json
  prefix :api

  resource :users do
    params do
      requires :user, type: Hash do
        requires :mail, type: String
        requires :password, type: String
      end
    end
    get '/' do
      client = MyMongo.new
      return (client.checkUser params[:user])
    end
  end
end
