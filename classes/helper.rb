class Helper
  @@verify_url = 'http://192.168.33.11/verify.html'
  
  def self.toJSON doc
    return doc.to_s.gsub('BSON::','').gsub('"','\'').gsub('=>',':')    
  end  
  
  def self.verify_url
    return @@verify_url
  end
end
