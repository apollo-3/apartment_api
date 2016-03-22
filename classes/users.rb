require 'digest'
require_relative 'db'
require_relative 'helper'

class Users
  MSGS = {
           'no_such_mail' => {'en' => 'There is no such email', 'ru' => 'Нет такой почты'},
           'bad_user' => {'en' => 'User doesn\'t exists', 'ru' => 'Такой пользователь не существует'},
           'bad_token' => {'en' => 'Token has expired', 'ru' => 'Токен недействителен'}
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
        return "{'success': 'ok'}"
      else
       return "{'error': \'#{MSGS['bad_token']['en']}\'}"
      end
    end
  end
  def checkUser user
    obj = @db.con[:users].find(:mail => user[:mail])
    if obj.count >= 1 
      obj = obj.first
      if obj[:password] == user[:password]
        token = setToken user[:mail]
        return "{'success': 'ok', 'token': \'#{token}\'}"
      else
        return "{'error': \'#{MSGS['bad_user']['en']}\'}"
      end
    else
        return "{'error': \'#{MSGS['no_such_mail']['en']}\'}"
    end
    @db.close
  end
end
