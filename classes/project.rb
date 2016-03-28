require_relative 'projects'

class Project < Grape::API
  format :json
  prefix :api
  
  resource 'projects' do
    params do
      requires :mail, type: String
      requires :token, type: String
      requires :defLang, type: String
    end
    post '/getProject' do
      client = Projects.new params[:defLang]
      return client.getProjects params[:mail], params[:token]
    end
    
    params do
      requires :project, type: Hash do
        requires :mail, type: String
        requires :token, type: String
        requires :name, type: String
        requires :flats, type: Array[Hash]
        requires :defLang, type: String
        requires :was_shared, type: Boolean
      end      
    end
    post '/saveProject' do
      client = Projects.new params[:project][:defLang]
      return client.updateProject params[:project]
    end
    
    params do
      requires :mail, type: String
      requires :token, type: String
      requires :name, type: String
      requires :defLang, type: String 
      requires :shared, type: Boolean       
    end
    post '/delProject' do
      client = Projects.new params[:defLang]
      return client.delProject params[:mail], params[:token], params[:name], params[:shared]
    end    
    
  end
end