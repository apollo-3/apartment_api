require 'mongo'

class Db
  attr_accessor :con
  def initialize db
    @con = Mongo::Client.new([ '127.0.0.1:27017' ], :database => db)
  end
  def close
    @con.close
  end
end
