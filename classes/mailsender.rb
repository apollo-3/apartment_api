require 'net/smtp'
class Mailsender  
  def initialize opts
    @to = opts[:to]
    @from = opts[:from]
    @message = opts[:message]
  end
  def send
    Net::SMTP.start('localhost') do |smtp|
      smtp.send_message message, @from, @to
    end    
  end
end