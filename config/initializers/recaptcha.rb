Recaptcha.configure do |config|
  config.site_key  = ENV['RECAPTCHA_SITE_KEY']
  config.secret_key = ENV['RECAPTCHA_SECRET_KEY']
end

#export RECAPTCHA_SITE_KEY="6Ld_iSIUAAAAAC2VRB5HPMSoEvQb4UGREvqbxGbQ"
#export RECAPTCHA_SECRET_KEY="6Ld_iSIUAAAAAClJtl3YV7HfT4B4idylgMrBLQ9k"
