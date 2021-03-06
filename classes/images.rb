require_relative 'db'
require_relative 'helper'
require 'tempfile'
require 'fileutils'
require_relative 'users'

class Images
  def initialize defLang
    @db = Db.new Helper.DB_NAME
    defLang = 'en' if !Helper.LANGS.include? defLang
    @def_lang = defLang
  end
  def uploadImage image, mail, token
    resp = nil;
    client = Users.new @def_lang
    valid_token = client.checkToken(mail, token)
    client.closeDb
    
    if valid_token.has_key? 'success'
      tmp = image['tempfile']
      oldName = tmp.path.split('/').last
      newName = mail + '_' + Helper.getTimeStamp + '_' + image['filename']
      FileUtils.cp(tmp.path, Helper.IMG_FOLDER)
      File.rename(Helper.IMG_FOLDER + oldName, Helper.IMG_FOLDER + newName)       
      File.delete tmp.path 
      Helper.resizeImage(Helper.IMG_FOLDER + newName) 
      resp = {'image' => {'img' => newName}}
    else
      resp = valid_token
    end
    
    @db.close
    return resp
  end
  def delImage image, mail, token
    resp = nil;
    client = Users.new @def_lang
    valid_token = client.checkToken(mail, token)
    client.closeDb  
    if valid_token.has_key? 'success'
      File.delete(Helper.IMG_FOLDER + image) if File.exist?(Helper.IMG_FOLDER + image)
      resp = {'success' => 'ok'}
    else
      resp = valid_token
    end
    @db.close
    return resp    
  end
  def groupDelImage imgArr, mail, token
    resp = nil;
    client = Users.new @def_lang
    valid_token = client.checkToken(mail, token)
    if valid_token.has_key? 'success'
      imgArr.each do |img|
        toDel = Helper.IMG_FOLDER + img
        File.delete(toDel) if File.exist?(toDel)
        resp = {'success' => 'ok'}
      end
    else
      resp = vali_token
    end
    return resp
  end
end