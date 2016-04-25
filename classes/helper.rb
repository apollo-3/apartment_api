require 'rmagick'

class Helper
  @@VERIFY_URL = 'http://192.168.33.11/verify.html'
  @@LANGS = ['en', 'ru']
  @@MSGS = {
            'no_such_mail' => {'en' => 'There is no such email', 'ru' => 'Нет такой почты'},
            'bad_pass' => {'en' => 'password is wrong', 'ru' => 'Неверный пароль'},
            'bad_token' => {'en' => 'Token has expired', 'ru' => 'Токен недействителен'},
            'user_deleted' => {'en' => 'User was deleted', 'ru' => 'Пользователь был удален'},
            'mail_exists' => {'en' => 'This email is already used', 'ru' => 'Данный адрес почты уже используется'},
            'user_deleted' => {'en' => 'user was deleted', 'ru' => 'Пользователь удален'},
            'user_updated' => {'en' => 'User was updated', 'ru' => 'Данные пользователя были изменены'},
            'user_created' => {'en' => 'User was created', 'ru' => 'Пользователь был зарегистрирован'},
            'not_verified' => {'en' => 'User is not verified', 'ru' => 'Пользователь не проверен'},
            'request_reset' => {'en' => 'Follow the url to reset password', 'ru' => 'Перейдите по ссылке, чтобы сбросить пароль'},
            'token_verified' => {'en' => 'Token was verified', 'ru' => 'Токен проверен'},
            'temp_password' => {'en' => 'Temporary password is', 'ru' => 'Временный пароль'},
            'cant_reset' => {'en' => 'You can\'t reset, cause user was not verified', 'ru' => 'Вы не можете сбросить пароль, так как пользователь пока не прошел проверку почты'},
            'pass_changed' => {'en' => 'Password changed', 'ru' => 'Пароль изменен'},
            'unknown' => {'en' => 'Error is unknown', 'ru' => 'Неизвестная ошибка'},
            'project_saved' => {'en' => 'Project was saved successfully', 'ru' => 'Проект был сохранен'},
            'project_deleted' => {'en' => 'Project was deleted', 'ru' => 'Проект был удален'},
            'mail_length_limit' => {'en' => "EMail length exceeded the limit", 'ru' => "Длина EMail превысила лимит"}
         }
  @@TABLE_USERS = :users
  @@TABLE_PROJECTS = :projects
  @@DB_NAME = 'apartments'
  @@IMG_FOLDER = '/var/apartment_ui/public/images/'
  @@MAX_MAIL_LENGTH = 32
  @@MAX_NAME_LENGTH = 32
  @@MAX_BIRTH_YEAR = 2200
  @@MAX_PHONE_LENGTH = 24
  @@MAX_GEONAME_LENGTH = 32  
  @@MAX_LANG_LENGTH = 3
  
  @@MAX_NAME_LENGTH = 22
  @@MAX_RATE_LENGTH = 10  
  @@MAX_DESCRIPTION_LENGTH = 256
  @@MAX_CURRENCY_LENGTH = 3
  
  @@MAX_ADDRESS_LENGTH = 64
  @@MAX_LINK_LENGTH = 64  
  @@MAX_FLOOR = 300
  @@MAX_PRICE_LENGTH = 16
  @@MAX_STARS = 10
  @@MAX_CALLHIST_LENGTH = 8  
  
  # def self.toJSON doc
    # return doc.to_s.gsub('BSON::','').gsub('"','\'').gsub('=>',':')    
  # end  
  
  def self.VERIFY_URL
    return @@VERIFY_URL
  end  
  def self.LANGS
    return @@LANGS
  end  
  def self.MSGS
    return @@MSGS
  end    
  def self.TABLE_USERS
    return @@TABLE_USERS
  end   
  def self.DB_NAME
    return @@DB_NAME
  end     
  def self.TABLE_PROJECTS
    return @@TABLE_PROJECTS
  end
  def self.IMG_FOLDER
    return @@IMG_FOLDER
  end  
  def self.MAX_MAIL_LENGTH
    return @@MAX_MAIL_LENGTH
  end  
  def self.MAX_NAME_LENGTH
    return @@MAX_NAME_LENGTH
  end    
  def self.MAX_BIRTH_YEAR
    return @@MAX_BIRTH_YEAR
  end   
  def self.MAX_PHONE_LENGTH
    return @@MAX_PHONE_LENGTH
  end
  def self.MAX_GEONAME_LENGTH
    return @@MAX_GEONAME_LENGTH
  end  
  def self.MAX_LANG_LENGTH
    return @@MAX_LANG_LENGTH
  end    
  def self.MAX_NAME_LENGTH
    return @@MAX_NAME_LENGTH
  end   
  def self.MAX_RATE_LENGTH
    return @@MAX_RATE_LENGTH
  end   
  def self.MAX_DESCRIPTION_LENGTH
    return @@MAX_DESCRIPTION_LENGTH
  end 
  def self.MAX_CURRENCY_LENGTH
    return @@MAX_CURRENCY_LENGTH
  end 
  def self.MAX_ADDRESS_LENGTH
    return @@MAX_ADDRESS_LENGTH
  end
  def self.MAX_LINK_LENGTH
    return @@MAX_LINK_LENGTH
  end  
  def self.MAX_FLOOR
    return @@MAX_FLOOR
  end    
  def self.MAX_PRICE_LENGTH
    return @@MAX_PHONE_LENGTH
  end    
  def self.MAX_STARS
    return @@MAX_STARS
  end   
  def self.MAX_CALLHIST_LENGTH
    return @@MAX_CALLHIST_LENGTH
  end  
  
  def self.getTimeStamp
    stamp = Time.now.to_s.gsub(/-| |:|\+/, '')[0..-5]
    return stamp
  end  
  def self.resizeImage image
    size = 400
    img = Magick::Image.read(image).first
    resized = img.resize_to_fit(size)
    if img.columns > size
      tempName = File.dirname(image) + '/M' + File.basename(image)
      resized.write(tempName) do
        self.quality = 100
      end
      File.delete image
      File.rename(tempName, image)
    end
    img.destroy!
    resized.destroy!    
  end
  
end
