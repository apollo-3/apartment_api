require 'digest'
require_relative 'db'
require_relative 'helper'

class Users
  MSGS = {
            'no_such_mail' => {'en' => 'There is no such email', 'ru' => 'Нет такой почты'},
            'bad_user' => {'en' => 'User doesn\'t exist', 'ru' => 'Такой пользователь не существует'},
            'bad_token' => {'en' => 'Token has expired', 'ru' => 'Токен недействителен'},
            'user_deleted' => {'en' => 'User was deleted', 'ru' => 'Пользователь был удален'},
            'mail_exists' => {'en' => 'This email is already used', 'ru' => 'Данный адрес почты уже используется'},
            'user_deleted' => {'en' => 'User was deleted', 'ru' => 'Пользователь удален'},
            'user_updated' => {'en' => 'User was updated', 'ru' => 'Данные пользователя были изменены'}            
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
    obj = @db.con[:users].find({:mail => mail, :token => token})    
    if obj.count >= 1
      if obj.first[:token] == token
        return {'success' => 'ok'}
      else
       return {'error' => MSGS['bad_token']['en']}
      end
    end
  end
  def checkUser user
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1 
      obj = obj.first
      if obj[:password] == user[:password]
        token = setToken user[:mail]
        return {'success' => 'ok', 'token' => token}
      else
        return {'error' => MSGS['bad_user']['en']}
      end
    else
        return {'error' => MSGS['no_such_mail']['en']}
    end
    @db.close
  end
  def logout user
    valid_token = checkToken user['mail'], user['token']
    if valid_token.has_key?('success')
      setToken user[:mail]
    end
  end
  def delUser user
    valid_token = checkToken(user[:mail], user[:token])
    if valid_token.has_key?('success')    
      @db.con[:users].find(:mail => user[:mail]).delete_one
      return {'success' => MSGS['user_deleted']['en']}
    else
      return valid_token
    end
    @db.close
  end
  def newUser user
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1
      return {'error' => MSGS['mail_exists']['en']}
    else
      @db.con[:users].insert_one user
      return {'success' => MSGS['user_created']['en']}
    end
    @db.close
  end
  def updateUser old_mail, user
    valid_token = checkToken(old_mail, user[:token])
    if valid_token.has_key?('success')
      @db.con[:users].find(user).update_one(user)
      return {'success' => MSGS['user_updated']['en']}
    else
      return valid_token
    end
  end
end