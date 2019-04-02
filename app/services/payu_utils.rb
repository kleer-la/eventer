module PayuUtils

  CURRENCY="COP"
  API_KEY= ENV['PAYU_CO_API_KEY'] || "4Vj8eK4rloUd272L48hsrarnUA"
  MERCHANT_ID=ENV['PAYU_CO_MERCHANT_ID'] || "508029"
  WEB_CHECKOUT_URL=ENV['PAYU_CO_WEBCHECKOUT_URL'] || "https://sandbox.checkout.payulatam.com/ppp-web-gateway-payu/"
  ACCOUNT_ID = ENV['PAYU_CO_ACCOUNT_ID'] || "512321"
  TEST =ENV['PAYU_CO_TEST_OPTION'] || 1
  DOMAIN = ENV['PUBLIC_DOMAIN'] || "http://localhost:3000"
  RESPONSE_URL=DOMAIN+"/events/payuco_response"
  CONFIRMATION_URL=DOMAIN+"/events/payuco_confirmation"

  ESTADOS = {4 => :APROBADO, 6 => :DECLINADO, 5=> :EXPIRADO}
  RESPUESTAS = {1	=> "Transacción aprobada",
                4 => "Transacción rechazada por entidad financiera",
                5 => "Transacción rechazada por el banco",
                6 => "Fondos insuficientes",
                7 => "Tarjeta inválida",
                8 => "Contactar entidad financiera",
                9 => "Tarjeta vencida",
                10 =>"Tarjeta restringida",
                14 => "Transacción inválida",
                17 => "El valor excede el máximo permitido por la entidad",
                19 => "Transacción abandonada por el pagador",
                22 => "Tarjeta no autorizada para comprar por internet",
                23 => "Transacción rechazada por sospecha de fraude",
                20 => "Transacción expirada"
  }


  def find_signature reference_code, pricing, state_pol=nil
    format="#{API_KEY}~#{MERCHANT_ID}~#{reference_code}~#{pricing}~#{CURRENCY}"
    puts "sign plain: #{format}"
    if state_pol
      format+="~#{state_pol}"
    end
    Digest::MD5.hexdigest format
  end
end