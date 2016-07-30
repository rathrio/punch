require 'net/smtp'
require 'erb'
require 'tempfile'

# Delivers a mail to Brigitte with the current BRF file attached.
class BRFMailer

  attr_accessor :smtp_domain, :smtp_server, :smtp_port, :smtp_user, :smtp_pw,
    :receiver, :cc, :bcc, :brf_filepath, :month_name, :body

  def initialize(brf_filepath, month_name)
    @brf_filepath = brf_filepath
    @month_name   = month_name

    # Load mailer config.
    config.mailer_config.each do |k, v|
      send("#{k}=", v) if respond_to? k
    end

    @body = gets_tmp 'body', body
  end

  def cc
    return smtp_user if @cc.nil? || @cc.empty?
    @cc
  end

  def body=(new_body)
    @body = ERB.new(new_body).result(binding)
  end

  def month_name
    @month_name.capitalize
  end

  def message(encode_attachment = true)
    boundary = "superUniqueIdentifier567"
    filename = File.basename brf_filepath
    file_content = File.read brf_filepath
    # Base64
    encoded_brf_file_content = [file_content].pack "m"

<<EOM
From: #{smtp_user}
To: #{receiver}
Cc: #{cc}
Subject: Stunden #{month_name.capitalize}
MIME-VERSION: 1.0
Content-Type: multipart/mixed; boundary=#{boundary}
--#{boundary}
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}

--#{boundary}
Content-Type: multipart/mixed; name=\"#{filename}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{filename}"

#{encode_attachment ? encoded_brf_file_content : file_content}
--#{boundary}--
EOM
  end

  def deliver
    smtp = Net::SMTP.new smtp_server, smtp_port
    smtp.enable_ssl
    smtp.start(smtp_domain, smtp_user, smtp_pw, :plain) do |sender|
      sender.send_message(message, smtp_user, receiver, cc)
    end
  end

  def config
    Punch.config
  end

end
