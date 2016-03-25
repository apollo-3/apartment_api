require_relative 'projects'

class Project < Grape::API
  format :json
  prefix :api
  
  resource 'projects' do
    params do
      requires :mail, type: String
      requires :token, type: String
    end
    post '/getProject' do
      client = Projects.new params[:defLang]
      return client.getProjects params[:mail], params[:token]
    end
    
  end
end