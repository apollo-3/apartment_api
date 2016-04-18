require_relative 'db'
require_relative 'helper'
require 'date'
require 'time'

class Projects
  def initialize defLang
    @db = Db.new Helper.DB_NAME
    defLang = 'en' if !Helper.LANGS.include? defLang
    @def_lang = defLang
  end
  def self.delExtraFields obj
    obj.delete 'mail'
    obj.delete 'token'
    obj.delete 'defLang'
    obj.delete 'was_shared'    
  end
  def getProjects mail, token
    resp = nil
    obj = @db.con[Helper.TABLE_USERS].find({:mail => mail, :token => token})
    if obj.count >= 1
      obj = obj.first
      if !obj.has_key? 'projects'
        resp = {'error' => Helper.MSGS['unknown'][@def_lang]}        
      else
        resp = obj[:projects]
        shared = @db.con[Helper.TABLE_PROJECTS].find({:owners => mail}).projection({'_id' => 0})
        if shared.count >= 1
          resp = obj[:projects] + shared.to_a
        end
      end
    else
      resp = {'error' => Helper.MSGS['bad_token'][@def_lang]}
    end
    @db.close
    return resp
  end
  def updateProject project
    resp = {'error' => Helper.MSGS['unknown'][@def_lang]}
    client = Users.new @def_lang
    mail = project[:mail]    
    was_shared = project[:was_shared]
    valid_token = client.checkToken mail, project[:token]
    client.closeDb
    project['creation_date'] = Time.parse(project['creation_date'])
    project['flats'].each do |flat|
      if flat[:modified] == 'update'
        flat[:modified] = Time.now
      else
        flat[:modified] = Time.parse flat[:modified]
      end
    end
    if valid_token.has_key? 'success'
      Projects.delExtraFields project
      oldName = project['name']
      if was_shared
        if project['shared']        
          @db.con[Helper.TABLE_PROJECTS].update_one({:owners => mail, :name => project[:name]}, project)
        else
          project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])        
          project['owners'] = [mail]
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$addToSet' => {'projects' => project}})
          @db.con[Helper.TABLE_PROJECTS].delete_one({:owners => mail, :name => oldName})
        end
        resp = {'success' => 'ok'}       
      else
        if project['shared']
          project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])
          @db.con[Helper.TABLE_PROJECTS].insert_one(project)
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$pull' => {:projects => {'name' => oldName}}})           
        else
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail, :projects => {'$elemMatch' => {:name => project[:name]}}},{'$set' => {'projects.$' => project}})        
        end
      end
      resp = {'success' => Helper.MSGS['project_saved'][@def_lang], 'project' => project}
    else
      resp = valid_token['error']
    end 
    @db.close
    return resp
  end
  def createProject project
    resp = {'error' => Helper.MSGS['unknown'][@def_lang]}
    client = Users.new @def_lang
    mail = project[:mail]    
    valid_token = client.checkToken mail, project[:token]
    client.closeDb
    project[:creation_date] = Time.now
    oldName = project['name']
    project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])    
    if valid_token.has_key? 'success'
      Projects.delExtraFields project
      if project['shared'] 
        project['owners'].push(mail) if !project['owners'].include?(mail)
        @db.con[Helper.TABLE_PROJECTS].insert_one(projectFilter(project))
      else
        project['owners'] = [mail]
        @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$addToSet' => {:projects => projectFilter(project)}})
      end
      resp = {'success' => Helper.MSGS['project_saved'][@def_lang], 'project' => project}
    else
      resp = valid_token['error']
    end 
    @db.close
    return resp      
  end
  def getAvailableProjectName mail, name, shared
    newName = name
    result = nil
    stamp = Time.now.to_s.gsub(/-| |:|\+/ ,'')[0..-5];
    dubls = 1    
    if shared
      result = @db.con[Helper.TABLE_PROJECTS].find({:name => Regexp.new(name)})
      newName = "#{stamp}_#{result.count.to_i + 1}_#{name}" if result.count > 0
    else
      result = @db.con[Helper.TABLE_USERS].find({:mail => mail})
      if result.count > 0
        result.first['projects'].each do |item|
          if Regexp.new(name).match(item[:name])!=nil
            dubls = dubls + 1
          end
        end
        newName = "#{stamp}_#{dubls}_#{name}" if dubls > 1
      end
    end
    return newName
  end
  def delProject mail, token, name, shared
    resp = nil;
    client = Users.new @def_lang
    valid_token = client.checkToken mail, token
    client.closeDb 
    if valid_token.has_key? 'success'
      if shared
        @db.con[Helper.TABLE_PROJECTS].delete_one({:name => name, :owners => mail})
      else
        @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$pull' => {'projects' => {'name' => name}}})
      end
      resp = {'success' => Helper.MSGS['project_deleted'][@def_lang]}
    else
      resp = valid_token['error']
    end    
    @db.close
    return resp;
  end
  def projectFilter project
    project[:name] = project[:name][0..(Helper.MAX_NAME_LENGTH-1)] if project[:name].length > Helper.MAX_NAME_LENGTH
    project[:currency] = project[:currency][0..(Helper.MAX_CURRENCY_LENGTH-1)] if project[:currency].length > Helper.MAX_CURRENCY_LENGTH   
    project[:rate] = project[:rate][0..(Helper.MAX_RATE_LENGTH-1)] if project[:rate].length > Helper.MAX_RATE_LENGTH
    project[:description] = project[:description][0..(Helper.MAX_DESCRIPTION.LENGTH-1)] if project[:description].length > Helper.MAX_DESCRIPTION_LENGTH
    i = 0
    project[:owners].each do |owner|
      project[:owners][i] = project[:owners][i][0..(Helper.MAX_MAIL_LENGTH - 1)] if owner.length > Helper.MAX_MAIL_LENGTH
      i = i + 1      
    end    
    return project
  end
end