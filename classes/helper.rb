class Helper
  def self.toJSON doc
    return doc.to_s.gsub('BSON::','').gsub('"','\'').gsub('=>',':')    
  end
end
