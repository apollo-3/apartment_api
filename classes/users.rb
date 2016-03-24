require 'digest'
require_relative 'db'
require_relative 'helper'

class Users
  MSGS = {
            'no_such_mail' => {'en' => 'There is no such email', 'ru' => 'Нет такой почты'},
            'bad_pass' => {'en' => 'Password is wrong', 'ru' => 'Неверный пароль'},
            'bad_token' => {'en' => 'Token has expired', 'ru' => 'Токен недействителен'},
            'user_deleted' => {'en' => 'User was deleted', 'ru' => 'Пользователь был удален'},
            'mail_exists' => {'en' => 'This email is already used', 'ru' => 'Данный адрес почты уже используется'},
            'user_deleted' => {'en' => 'User was deleted', 'ru' => 'Пользователь удален'},
            'user_updated' => {'en' => 'User was updated', 'ru' => 'Данные пользователя были изменены'},
            'user_created' => {'en' => 'User was created', 'ru' => 'Пользователь был зарегистрирован'},
            'not_verified' => {'en' => 'User is not verified', 'ru' => 'Пользователь не проверен'},
            'request_reset' => {'en' => 'Follow the url to reset password', 'ru' => 'Перейдите по ссылке, чтобы сбросить пароль'},
            'token_verified' => {'en' => 'Token was verified', 'ru' => 'Токен проверен'},
            'temp_password' => {'en' => 'Temporary password is', 'ru' => 'Временный пароль'},
            'cant_reset' => {'en' => 'You can\'t reset, cause user was not verified', 'ru' => 'Вы не можете сбросить пароль, так как пользователь пока не прошел проверку почты'}
         }
  def initialize
    @db = Db.new 'apartments'
    @def_lang = 'en'
  end  
  def setToken mail
    token = Digest::MD5.hexdigest "#{mail}.#{Time.now().to_i.to_s}" 
    @db.con[:users].find(:mail => mail).update_one({'$set' => {:token => token}})
    return token
  end
  def checkToken mail, token
    resp = {'error' => MSGS['bad_token'][@def_lang]}
    obj = @db.con[:users].find({:mail => mail, :token => token})
    if obj.count >= 1
      obj = obj.first
      if obj[:token] == token
        resp = {'success' => MSGS['token_verified'][obj[:lang]]}
      end
    end
    return resp
  end
  def login user
    resp = nil
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1 
      obj = obj.first
      if obj[:password] == user[:password]
        if obj[:verified]
          token = setToken user[:mail]
          obj.delete '_id'
          obj.delete 'creation_date'
          obj.delete 'verified'
          obj.delete 'password'
          obj.delete 'token'
          resp = {'success' => 'ok', 'token' => token, 'user' => obj}
        else
          resp = {'error' => MSGS['not_verified'][obj[:lang]]}
        end
      else
        resp = {'error' => MSGS['bad_pass'][obj[:lang]]}
      end
    else
        resp = {'error' => MSGS['no_such_mail'][@def_lang]}
    end
    @db.close
    return resp
  end
  def logout user
    valid_token = checkToken user['mail'], user['token']
    if valid_token.has_key?('success')
      setToken user[:mail]
    end
    @db.close
  end
  def delUser user
    resp = nil
    valid_token = checkToken(user[:mail], user[:token])
    if valid_token.has_key?('success')
      obj = @db.con[:users].find({:mail => user[:mail], :password => user[:password]})
      if obj.count < 1
        resp = {'error' => MSGS['bad_pass'][@def_lang]}
      else
        @db.con[:users].find(:mail => user[:mail]).delete_one
        resp = {'success' => MSGS['user_deleted'][@def_lang]}
      end
    else
      resp = valid_token
    end
    @db.close
    return resp
  end
  def newUser user
    resp = nil
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1
      resp = {'error' => MSGS['mail_exists'][user['lang']]}
    else
      user[:verified] = false
      user[:creation_date] = Time.now
      @db.con[:users].insert_one(user)
      token = setToken user['mail']
      resp = {'success' => MSGS['user_created'][user['lang']], 'verifing_url' => Helper.verify_url + "?mail=#{user[:mail]}&token=#{token}&action=verify"}
    end
    @db.close
    return resp
  end
  def updateUser old_mail, user
    resp = nil
    valid_token = checkToken(old_mail, user[:token])
    if valid_token.has_key?('success')
      @db.con[:users].find(user).update_one user
      resp ={'success' => MSGS['user_updated'][user[:lang]]}
    else
      resp =  valid_token
    end
    @db.close
    return resp
  end
  def setVerified mail, token
    valid_token = checkToken(mail, token)
    if valid_token.has_key?('success')
      @db.con[:users].find(:mail => mail).update_one({'$set' => {'verified' => true}})      
    end
    @db.close
    return valid_token
  end
  def requestReset mail
    resp = nil;
    obj = @db.con[:users].find(:mail => mail)
    if obj.count >= 1
      obj = obj.first
      if !obj['verified']
        resp = {'error' => MSGS['cant_reset'][obj[:lang]]}        
      else
        token = setToken mail
        resp = {'success' => MSGS['request_reset'][obj[:lang]], 'reset_url' => Helper.verify_url + "?mail=#{mail}&token=#{token}&action=reset"}
      end
    else
      resp = {'error' => MSGS['no_such_mail'][@def_lang]}
    end
    @db.close
    return resp
  end
  def resetPassword mail, token
    valid_token = checkToken(mail, token)
    resp = valid_token
    if valid_token.has_key?('success')
      password = Random.rand(10000).to_s
      @db.con[:users].find(:mail => mail).update_one({'$set' => {'password' => Digest::MD5.hexdigest(password)}})
      resp = {'success' => "#{MSGS['temp_password'][@def_lang]} #{password}"}
    end
    @db.close
    return resp
  end
end
