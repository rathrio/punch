require 'net/smtp'

# Delivers a mail to Brigitte with the current BRF file attached.
class BRFMailer

  attr_accessor :smtp_domain, :smtp_server, :smtp_port, :smtp_user, :smtp_pw,
    :receiver, :cc, :bcc, :brf_filepath, :month_name, :body

  def initialize(brf_filepath, month_name)
    # Load mailer config.
    Punch.config.mailer_config.each do |k, v|
      send("#{k}=", v) if respond_to? k
    end

    @brf_filepath = brf_filepath
    @month_name   = month_name
  end

  def deliver
    boundary = "superUniqueIdentifier567"
    filename = File.basename brf_filepath
    encoded_brf_file_content = [File.read(brf_filepath)].pack "m"

    message = <<EOM
From: #{smtp_user}
To: #{receiver}
Subject: Stunden #{month_name.capitalize}
MIME-VERSION: 1.0
Content-Type: multipart/mixed; boundary=#{boundary}
--#{boundary}
Content-Type: text/plain
Content-Transfer-Encoding:8bit

Hallo Tanja,

anbei findest du meine Stunden vom #{month_name.capitalize}.

lg Radi

--#{boundary}
Content-Type: multipart/mixed; name=\"#{filename}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{filename}"

#{encoded_brf_file_content}
--#{boundary}--
EOM

    smtp = Net::SMTP.new smtp_server, smtp_port
    smtp.enable_ssl
    smtp.start(smtp_domain, smtp_user, smtp_pw, :plain) do |sender|
      sender.send_message(message, smtp_user, receiver)
    end
  end

end
