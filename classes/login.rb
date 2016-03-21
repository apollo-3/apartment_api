class Login < Grape::API
  format :json
  prefix :api
end

resource :users do
  get "/" do
  end
end
