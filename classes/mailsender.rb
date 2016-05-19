require 'net/smtp'
class Mailsender  
  def initialize opts
    @to = opts[:to]
    @from = opts[:from]
    @message = opts[:message]
  end
  def send
    begin  
    Net::SMTP.start('localhost') do |smtp|
      smtp.send_message @message, @from, @to
    end
    rescue Exception
      Logger.write(@message);
    end
  end
end