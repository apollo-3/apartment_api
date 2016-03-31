require 'digest'
require_relative 'db'
require_relative 'helper'

class Users
  def initialize defLang
    @db = Db.new Helper.DB_NAME
    defLang = 'en' if !Helper.LANGS.include? defLang
    @def_lang = defLang
  end
  def self.delExtraFields obj
    obj.delete '_id'
    obj.delete 'creation_date'
    obj.delete 'verified'
    obj.delete 'password'
    obj.delete 'token'  
    obj.delete 'projects'
    return obj
  end
  def setToken mail
    token = Digest::MD5.hexdigest "#{mail}.#{Time.now().to_i.to_s}" 
    @db.con[Helper.TABLE_USERS].find(:mail => mail).update_one({'$set' => {:token => token}})
    return token
  end
  def checkToken mail, token
    resp = {'error' => Helper.MSGS['bad_token'][@def_lang]}
    obj = @db.con[Helper.TABLE_USERS].find({:mail => mail, :token => token})
    if obj.count >= 1
      obj = obj.first
      if obj[:token] == token
        obj = Users.delExtraFields obj
        resp = {'success' => Helper.MSGS['token_verified'][obj[:lang]], 'user' => obj}
      end
    end
    return resp
  end
  def login user
    user.delete 'defLang'
    resp = nil
    obj = @db.con[Helper.TABLE_USERS].find(:mail => user[:mail])
    if obj.count >= 1 
      obj = obj.first
      if obj[:password] == user[:password]
        if obj[:verified]
          token = setToken user[:mail]
          obj = Users.delExtraFields(obj)
          resp = {'success' => 'ok', 'token' => token, 'user' => obj}
        else
          resp = {'error' => Helper.MSGS['not_verified'][obj[:lang]]}
        end 
      else
        resp = {'error' => Helper.MSGS['bad_pass'][obj[:lang]]}
      end
    else
        resp = {'error' => Helper.MSGS['no_such_mail'][@def_lang]}
    end
    @db.close
    return resp
  end
  def logout user
    user.delete 'defLang'
    valid_token = checkToken user['mail'], user['token']
    if valid_token.has_key?('success')
      setToken user[:mail]
    end
    @db.close
  end
  def delUser user
    user.delete 'defLang'
    resp = nil
    valid_token = checkToken(user[:mail], user[:token])
    if valid_token.has_key?('success')
      obj = @db.con[Helper.TABLE_USERS].find({:mail => user[:mail], :password => user[:password]})
      if obj.count < 1
        resp = {'error' => Helper.MSGS['bad_pass'][@def_lang]}
      else
        @db.con[Helper.TABLE_USERS].find(:mail => user[:mail]).delete_one
        resp = {'success' => Helper.MSGS['user_deleted'][@def_lang]}
      end
    else
      resp = valid_token
    end
    @db.close
    return resp
  end
  def newUser user
    user.delete 'defLang'    
    user['lang'] = @def_lang
    resp = nil
    obj = @db.con[Helper.TABLE_USERS].find(:mail => user[:mail])
    if obj.count >= 1
      resp = {'error' => Helper.MSGS['mail_exists'][@def_lang]}
    else
      user[:verified] = false
      user[:creation_date] = Time.now
      user[:projects] = []
      @db.con[:users].insert_one(user)
      token = setToken user['mail']
      resp = {'success' => Helper.MSGS['user_created'][@def_lang], 'verifing_url' => Helper.VERIFY_URL + "?mail=#{user[:mail]}&token=#{token}&action=verify"}
    end
    @db.close
    return resp
  end
  def updateUser user
    user.delete 'defLang'
    resp = {'error' => Helper.MSGS['bad_pass'][@def_lang]}
    valid_token = checkToken(user[:mail], user[:token])
    if valid_token.has_key?('success')
      if user.has_key?('newPassword')
        result = @db.con[Helper.TABLE_USERS].update_one({:mail => user['mail'], :password => user['password']},{'$set' => {'password' => user['newPassword']}})
        if result.n == 1
          obj = Users.delExtraFields(@db.con[Helper.TABLE_USERS].find(:mail => user['mail']).first)
          resp = {'success' => Helper.MSGS['pass_changed'][obj['lang']], 'user' => obj}
        end
      else      
        result = @db.con[Helper.TABLE_USERS].update_one({:mail => user['mail'], :password => user['password']},{'$set' => user})
        if result.n == 1        
          obj = Users.delExtraFields(@db.con[Helper.TABLE_USERS].find(:mail => user['mail']).first)
          resp ={'success' => Helper.MSGS['user_updated'][user[:lang]], 'user' => obj}
        end
      end
    else
      resp =  valid_token
    end
    @db.close
    return resp
  end
  def setVerified mail, token
    valid_token = checkToken(mail, token)
    if valid_token.has_key?('success')
      @db.con[Helper.TABLE_USERS].find(:mail => mail).update_one({'$set' => {'verified' => true}})      
    end
    @db.close
    return valid_token
  end
  def requestReset mail
    resp = nil;
    obj = @db.con[Helper.TABLE_USERS].find(:mail => mail)
    if obj.count >= 1
      obj = obj.first
      if !obj['verified']
        resp = {'error' => Helper.MSGS['cant_reset'][obj[:lang]]}        
      else
        token = setToken mail
        resp = {'success' => Helper.MSGS['request_reset'][obj[:lang]], 'reset_url' => Helper.VERIFY_URL + "?mail=#{mail}&token=#{token}&action=reset"}
      end
    else
      resp = {'error' => Helper.MSGS['no_such_mail'][@def_lang]}
    end
    @db.close
    return resp
  end
  def resetPassword mail, token
    valid_token = checkToken(mail, token)
    resp = valid_token
    if valid_token.has_key?('success')
      password = Random.rand(10000).to_s
      @db.con[Helper.TABLE_USERS].find(:mail => mail).update_one({'$set' => {'password' => Digest::MD5.hexdigest(password)}})
      resp = {'success' => "#{Helper.MSGS['temp_password'][@def_lang]} #{password}"}
    end
    @db.close
    return resp
  end
  def getAllUsers mail, token
    resp = nil
    valid_token = checkToken mail, token
    if valid_token.has_key? 'success'
      objs = @db.con[Helper.TABLE_USERS].find({:verified => true}).projection({:mail => 1, '_id' => 0})
      if objs.count > 1
        out = []
        objs.each do |item|
          out.push item[:mail]
        end
        resp = {'success' => 'ok', 'users' => out}
      else
        resp = {'error' => Helper.MSGS['unknown'][@def_lang]}
      end
    else
      res = valid_token
    end
    @db.close
    return resp
  end
  def getData mail, token
    @db.close
    return checkToken mail, token    
  end
  def closeDb
    @db.close
  end
end
