require 'mongo'

class MyMongo
  attr_accessor :con
  def initialize
    @con = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'apartments')
  end
  def checkUser user
    puts user[:mail]
    obj = @con.client[:users].find_one(:mail => user[:mail])
    if obj[:password] == user[:password]
      return {:fine => 'fine'}
    else
      return {:error => 'error'}
    end
    @con.close
  end
end
