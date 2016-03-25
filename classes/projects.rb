require_relative 'db'
require_relative 'helper'

class Projects
  def initialize defLang
    @db = Db.new Helper.DB_NAME
    defLang = 'en' if !Helper.LANGS.include? defLang
    @def_lang = defLang
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
      end
    else
      resp = {'error' => Helper.MSGS['bad_token'][@def_lang]}
    end
    @db.close
    return resp
  end
end