require 'mail'

# Load smtp configs from Punch.config.
Mail.defaults do
  delivery_method :smtp, {
    :address              => Punch.config.smtp_server,
    :port                 => Punch.config.smtp_port,
    :user_name            => Punch.config.smtp_user,
    :password             => Punch.config.smtp_pw,
    :authentication       => :plain,
    :enable_starttls_auto => false,
    :ssl                  => true
  }
end

# Delivers a mail to Brigitte with the current BRF file attached.
class BRFMailer
  def initialize(brf_filepath, month_name)
    @brf_filepath = brf_filepath
    @month_name   = month_name
  end

  def deliver
    mail = Mail.new do
      from     Punch.config.smtp_user
      to       Punch.config.brigitte_mail
      bcc      Punch.config.smtp_user
      body     'HELLO WORLD!'
    end
    mail.subject = "Stunden #{@month_name.capitalize}"
    mail.add_file @brf_filepath
    mail.deliver
  end
end
