require 'net/smtp'

# Delivers a mail to Brigitte with the current BRF file attached.
class BRFMailer

  attr_accessor :smtp_domain, :smtp_server, :smtp_port, :smtp_user, :smtp_pw,
    :receiver, :cc, :bcc, :brf_filepath, :month_name

  def initialize(brf_filepath, month_name)
    # Load mailer config.
    Punch.config.mailer_config.each do |k, v|
      send("#{k}=", v) if respond_to? k
    end

    @brf_filepath = brf_filepath
    @month_name   = month_name
  end

  def deliver

    message = <<EOM
From: r.iyadurai@fadendaten.ch
To: rad.iyadurai@gmail.com
Subject: Stunden #{month_name.capitalize}

This is a test
EOM


    smtp = Net::SMTP.new smtp_server, smtp_port
    smtp.enable_ssl
    smtp.start(smtp_domain, smtp_user, smtp_pw, :plain) do |sender|
      sender.send_message(message, smtp_user, receiver)
    end
  end

end
