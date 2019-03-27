module PayuUtils

  CURRENCY="COP"
  API_KEY="11111"
  MERCHANT_ID="22222"

  def find_signature reference_code, pricing, state_pol=nil
    format="#{API_KEY}~#{MERCHANT_ID}~#{reference_code}~#{pricing}~#{CURRENCY}"
    if state_pol
      format+="~#{state_pol}"
    end
    Digest::MD5.hexdigest format
  end
end