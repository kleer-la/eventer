module PayuUtils

  CURRENCY="COP"
  API_KEY= ENV['PAYU_CO_API_KEY'] || "11111"
  MERCHANT_ID=ENV['PAYU_CO_MERCHANT_ID'] || "22222"
  WEB_CHECKOUT_URL=ENV['PAYU_CO_WEBCHECKOUT_URL'] || "https://sandbox.checkout.payulatam.com/ppp-web-gateway-payu/"
  ACCOUNT_ID = ENV['PAYU_CO_ACCOUNT_ID'] || "33333"
  TEST =ENV['PAYU_CO_TEST_OPTION'] || 1
  #RESPONSE_URL="http..."
  CONFIRMATION_URL="https://"+ENV['PUBLIC_DOMAIN']+"/events/payuco_confirmation"


  def find_signature reference_code, pricing, state_pol=nil
    format="#{API_KEY}~#{MERCHANT_ID}~#{reference_code}~#{pricing}~#{CURRENCY}"
    if state_pol
      format+="~#{state_pol}"
    end
    Digest::MD5.hexdigest format
  end
end