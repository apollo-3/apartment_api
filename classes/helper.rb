class Helper
  @@VERIFY_URL = 'http://192.168.33.11/verify.html'
  @@LANGS = ['en', 'ru']
  @@MSGS = {
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
            'cant_reset' => {'en' => 'You can\'t reset, cause user was not verified', 'ru' => 'Вы не можете сбросить пароль, так как пользователь пока не прошел проверку почты'},
            'pass_changed' => {'en' => 'Password changed', 'ru' => 'Пароль изменен'},
            'unknown' => {'en' => 'Error is unknown', 'ru' => 'Неизвестная ошибка'},
            'project_saved' => {'en' => 'Project was saved successfully', 'ru' => 'Проект был сохранен'},
            'project_deleted' => {'en' => 'Project was deleted', 'ru' => 'Проект был удален'}
         }
  @@TABLE_USERS = :users
  @@TABLE_PROJECTS = :projects
  @@DB_NAME = 'apartments'
  @@IMG_FOLDER = '/var/apartment_ui/public/images/'
  
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
end
