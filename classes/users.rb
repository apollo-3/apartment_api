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
            'not_verified' => {'en' => 'User is not verified', 'ru' => 'Пользователь не проверен'}
         }
  def initialize
    @db = Db.new 'apartments'
  end  
  def setToken mail
    token = Digest::MD5.hexdigest "#{mail}.#{Time.now().to_i.to_s}" 
    @db.con[:users].find(:mail => mail).update_one({'$set' => {:token => token}})
    return token
  end
  def checkToken mail, token
    resp = {'error' => MSGS['bad_token']['en']}
    obj = @db.con[:users].find({:mail => mail, :token => token})
    if obj.count >= 1
      if obj.first[:token] == token
        resp = {'success' => 'ok'}
      end
    end
    return resp
  end
  def checkUser user
    resp = nil
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1 
      obj = obj.first
      if obj[:password] == user[:password]
        if obj[:verified]
          token = setToken user[:mail]
          resp = {'success' => 'ok', 'token' => token}
        else
          resp = {'error' => MSGS['not_verified']['en']}
        end
      else
        resp = {'error' => MSGS['bad_pass']['en']}
      end
    else
        resp = {'error' => MSGS['no_such_mail']['en']}
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
      @db.con[:users].find(:mail => user[:mail]).delete_one
      resp = {'success' => MSGS['user_deleted']['en']}
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
      resp = {'error' => MSGS['mail_exists']['en']}
    else
      user[:verified] = false
      @db.con[:users].insert_one(user)
      token = setToken user['mail']
      resp = {'success' => MSGS['user_created']['en'], 'verifing_url' => "http://192.168.33.11/verify.html?mail=#{user[:mail]}&token=#{token}"}
    end
    @db.close
    return resp
  end
  def updateUser old_mail, user
    resp = nil
    valid_token = checkToken(old_mail, user[:token])
    if valid_token.has_key?('success')
      @db.con[:users].find(user).update_one user
      resp ={'success' => MSGS['user_updated']['en']}
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
end
