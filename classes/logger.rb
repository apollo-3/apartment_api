class Logger
  @@PATH = '/tmp/debug.log'
  def self.write out
    f = File.open(@@PATH, 'ab')
    timeStamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    f.write(timeStamp + '   ' + out + "\n")
    f.close
  end
end