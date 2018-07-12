Invitation.configure do |config|
  # config.user_model = '::User'
  config.user_registration_url = lambda do |params|
    url = ENV['FRONT_REGISTRATION_URL'] + '?'
    params.each do |k, v|
      url += "#{k}=#{v}&"
    end
    url[0...-1]
  end
  config.mailer_sender = ENV['MAILER_SENDER']
  config.routes = false
  # config.case_sensitive_email = true
end
