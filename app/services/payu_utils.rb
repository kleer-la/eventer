module PayuUtils

  CURRENCY="COP"
  API_KEY= ENV['PAYU_CO_API_KEY'] || "4Vj8eK4rloUd272L48hsrarnUA"
  MERCHANT_ID=ENV['PAYU_CO_MERCHANT_ID'] || "508029"
  WEB_CHECKOUT_URL=ENV['PAYU_CO_WEBCHECKOUT_URL'] || "https://sandbox.checkout.payulatam.com/ppp-web-gateway-payu/"
  ACCOUNT_ID = ENV['PAYU_CO_ACCOUNT_ID'] || "512321"
  TEST =ENV['PAYU_CO_TEST_OPTION'] || 1
  DOMAIN = ENV['PUBLIC_DOMAIN'] || "http://localhost:3000"
  #RESPONSE_URL="http..."
  CONFIRMATION_URL=DOMAIN+"/events/payuco_confirmation"

  def find_signature reference_code, pricing, state_pol=nil
    format="#{API_KEY}~#{MERCHANT_ID}~#{reference_code}~#{pricing}~#{CURRENCY}"
    if state_pol
      format+="~#{state_pol}"
    end
    Digest::MD5.hexdigest format
  end
end