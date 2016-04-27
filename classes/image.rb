require_relative 'images'

class Image < Grape::API
  format :json
  prefix :api
  
  resource 'images' do
    params do
      requires :image, type: File
      requires :mail, type: String
      requires :token, type: String
      requires :defLang, type: String
    end
    post '/uploadImage' do
      client = Images.new params[:defLang]
      return client.uploadImage params[:image], params[:mail], params[:token]
    end 
    
    params do
      requires :image, type: String
      requires :mail, type: String
      requires :token, type: String
      requires :defLang, type: String
    end
    post '/delImage' do
      client = Images.new params[:defLang]
      return client.delImage params[:image], params[:mail], params[:token]
    end  

    params do
      requires :data, type: Hash do
        requires :imgArr, type: Array
        requires :mail, type: String
        requires :token, type: String
        requires :defLang, type: String      
      end
    end
    post '/groupDelImage' do
      client = Images.new params[:data][:defLang]
      return client.groupDelImage params[:data][:imgArr], params[:data][:mail], params[:data][:token]
    end
    
  end
end