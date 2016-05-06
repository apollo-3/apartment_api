require_relative 'db'
require_relative 'helper'
require_relative 'users'
require_relative 'logger'
require 'date'
require 'time'
require 'csv'

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
          @db.con[Helper.TABLE_PROJECTS].update_one({:owners => mail, :name => project[:name]}, projectFilter(project, mail))
        else
          project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])        
          project['owners'] = [mail]
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$addToSet' => {'projects' => projectFilter(project, mail)}})
          @db.con[Helper.TABLE_PROJECTS].delete_one({:owners => mail, :name => oldName})
        end
        resp = {'success' => 'ok'}       
      else
        if project['shared']
          project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])
          @db.con[Helper.TABLE_PROJECTS].insert_one(projectFilter(project, mail))
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$pull' => {:projects => {'name' => oldName}}})           
        else
          @db.con[Helper.TABLE_USERS].update_one({:mail => mail, :projects => {'$elemMatch' => {:name => project[:name]}}},{'$set' => {'projects.$' => projectFilter(project, mail)}})        
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
    # Filter Account Limits
      projectsOverall = @db.con[Helper.TABLE_PROJECTS].find({:owners => mail}).count + valid_token['user']['projects'].length
      if  projectsOverall >= Helper.ACCOUNTS[valid_token['user']['account']][:projects]
        return resp
      end
    # Filter Account Limits ends
    project[:creation_date] = Time.now
    oldName = project['name']
    project['name'] = getAvailableProjectName(mail, project['name'], project['shared'])    
    if valid_token.has_key? 'success'
      Projects.delExtraFields project
      if project['shared'] 
        project['owners'].push(mail) if !project['owners'].include?(mail)
        @db.con[Helper.TABLE_PROJECTS].insert_one(projectFilter(project, mail))
      else
        project['owners'] = [mail]
        @db.con[Helper.TABLE_USERS].update_one({:mail => mail},{'$addToSet' => {:projects => projectFilter(project, mail)}})
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
  def projectFilter project, mail
    userClient = Users.new @def_lang
    obj = userClient.getUserInfo mail
    userClient.closeDb()
    
    project[:name] = project[:name][0..(Helper.MAX_NAME_LENGTH-1)] if project[:name].length > Helper.MAX_NAME_LENGTH
    project[:currency] = project[:currency][0..(Helper.MAX_CURRENCY_LENGTH-1)] if project[:currency].length > Helper.MAX_CURRENCY_LENGTH   
    project[:rate] = project[:rate][0..(Helper.MAX_RATE_LENGTH-1)] if project[:rate].length > Helper.MAX_RATE_LENGTH
    project[:description] = project[:description][0..(Helper.MAX_DESCRIPTION.LENGTH-1)] if project[:description].length > Helper.MAX_DESCRIPTION_LENGTH
    i = 0
    project[:owners].each do |owner|
      project[:owners][i] = project[:owners][i][0..(Helper.MAX_MAIL_LENGTH - 1)] if owner.length > Helper.MAX_MAIL_LENGTH
      i = i + 1      
    end  
    i = 0
    # Filter Account Limits
    project[:flats] = project[:flats][0..(Helper.ACCOUNTS[obj['user']['account']][:flats] - 1)] if project[:flats].length > Helper.ACCOUNTS[obj['user']['account']][:flats]
    # Filter Account Limits ends
    project[:flats].each do |flat|
      j = 0
      
      flat[:phones].each do |phone|
        project[:flats][i][:phones][j][:phone] = phone[:phone][0..(Helper.MAX_PHONE_LENGTH - 1)] if phone[:phone].length > Helper.MAX_PHONE_LENGTH
        j = j + 1
      end
      project[:flats][i][:address] = flat[:address][0..(Helper.MAX_ADDRESS_LENGTH - 1)] if flat[:address].length > Helper.MAX_ADDRESS_LENGTH
      project[:flats][i][:link] = flat[:link][0..(Helper.MAX_LINK_LENGTH - 1)] if flat[:link].length > Helper.MAX_LINK_LENGTH      
      project[:flats][i][:contact] = flat[:contact][0..(Helper.MAX_NAME_LENGTH - 1)] if flat[:contact].length > Helper.MAX_NAME_LENGTH            
      project[:flats][i][:floor] = 0 if flat[:floor] > Helper.MAX_FLOOR
      project[:flats][i][:buildYear] = 0 if flat[:buildYear] > Helper.MAX_BIRTH_YEAR
      project[:flats][i][:price] = 0 if flat[:price].to_s().length > Helper.MAX_PRICE_LENGTH
      project[:flats][i][:callHistory] = 'toCall' if flat[:callHistory].length > Helper.MAX_CALLHIST_LENGTH      
      project[:flats][i][:stars] = 0 if flat[:stars] > Helper.MAX_STARS
      # Filter Account Limits
      project[:flats][i][:images] = flat[:images][0..(Helper.ACCOUNTS[obj['user']['account']][:photos] - 1)] if flat[:images].length > Helper.ACCOUNTS[obj['user']['account']][:photos]      
      # Filter Account Limits ends      
      i = i + 1      
    end
    return project
  end
  def downloadProject mail, token, shared, name
    resp = {'error' => Helper.MSGS['unknown'][@def_lang]}
    client = Users.new @def_lang
    valid_token = client.checkToken mail, token
    client.closeDb
    if valid_token.has_key? 'success'
      doc = nil
      out = []
      if shared
        doc = @db.con[Helper.TABLE_PROJECTS].find({'owners' => mail, 'name' => name})        
      else
        doc = @db.con[Helper.TABLE_USERS].aggregate([{:$unwind => '$projects'},{:$match => {'mail' => mail, 'projects.name' => name}},{:$project => {'flats' => '$projects.flats'}}])             
      end
      if doc != nil && doc.count > 0
        heads = [
          Helper.TRANSLATIONS['address'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['contact'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['phones'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['price'][valid_token['user']['lang']].capitalize,          
          Helper.TRANSLATIONS['buildYear'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['floor'][valid_token['user']['lang']].capitalize,          
          Helper.TRANSLATIONS['callHistory'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['stars'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['link'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['owner'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['subway'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['shop'][valid_token['user']['lang']].capitalize,          
          Helper.TRANSLATIONS['park'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['school'][valid_token['user']['lang']].capitalize, 
          Helper.TRANSLATIONS['daycare'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['furniture'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['electronics'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['lastfloor'][valid_token['user']['lang']].capitalize,
          Helper.TRANSLATIONS['modified'][valid_token['user']['lang']].capitalize          
        ]
        out.push heads        
        doc.first[:flats].each do |flat|        
          row = []
          row.push flat[:address]
          row.push flat[:contact]
          phones = ''
          flat[:phones].each { |phone| phones = "#{phones}#{phone['phone']}, " }
          row.push phones.gsub(/, $/, '')
          row.push flat[:price]
          row.push flat[:buildYear]
          row.push flat[:floor]
          row.push Helper.TRANSLATIONS[flat[:callHistory]][valid_token['user']['lang']]
          row.push flat[:stars]
          row.push flat[:link]
          row.push (flat[:owner] == true ? '+' : '-')
          row.push (flat[:subway] == true ? '+' : '-')
          row.push (flat[:shop] == true ? '+' : '-')          
          row.push (flat[:park] == true ? '+' : '-')          
          row.push (flat[:school] == true ? '+' : '-')         
          row.push (flat[:daycare] == true ? '+' : '-')          
          row.push (flat[:furniture] == true ? '+' : '-')
          row.push (flat[:electronics] == true ? '+' : '-')          
          row.push (flat[:lastfloor] == true ? '+' : '-')
          row.push flat[:modified]          
          out.push row
        end
        CSV.open("#{Helper.REPORT_FOLDER}/#{mail}.csv", 'w') do |csv|
          out.each do |row|
            csv << row
          end
        end
        resp = {'success' => 'ok'}
      end
    end
    return resp
  end
end