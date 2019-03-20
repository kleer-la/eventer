require 'digest'

class PayuCoWebcheckoutService

  def initialize
    @webCheckoutUrl="https://sandbox.checkout.payulatam.com/ppp-web-gateway-payu/"
    @currency="COP"
    @apiKey="11111"
    @responseUrl="http..."
    @confirmationUrl="http..."
    @merchantId="22222"
    @accountId="33333"
    @iva = 19
  end

  def prepare_webcheckout event, participant
    pricing = find_pricing event
    iva = find_iva(pricing)
    reference_code = "#{event.id}---#{participant.id}---#{pricing}---#{get_time_in_milis(Time.now)}"
    webcheckout_data = {}
    webcheckout_data[:action]=@webCheckoutUrl
    webcheckout_data[:merchantId]= @merchantId
    webcheckout_data[:accountId]= @accountId
    webcheckout_data[:description]= "Pago por #{event.event_type.name}, de #{participant.fname} #{participant.lname} por #{pricing}"
    webcheckout_data[:referenceCode]= reference_code
    webcheckout_data[:amount]= pricing
    webcheckout_data[:tax]= iva
    webcheckout_data[:taxReturnBase]= pricing - iva
    webcheckout_data[:currency]= @currency
    webcheckout_data[:signature]= find_signature(reference_code,pricing)
    webcheckout_data[:test]= "1"
    webcheckout_data[:buyerEmail]= participant.email
    webcheckout_data[:buyerFullName]= "#{participant.fname} #{participant.lname}"
    webcheckout_data[:telephone]= participant.phone
    webcheckout_data[:responseUrl]= @responseUrl
    webcheckout_data[:confirmationUrl]= @confirmationUrl
    webcheckout_data[:extra1]= participant.id
    webcheckout_data[:extra2]= event.id
    webcheckout_data
  end

  private

  def find_pricing event
    if get_time_in_milis(Time.parse(event.eb_end_date.to_s)) >= get_time_in_milis(Time.now)
      event.eb_price.round(2)
    else
      event.list_price.round(2)
    end
  end

  def find_iva pricing
    ((pricing*@iva)/(100+@iva)).round(2)
  end

  def get_time_in_milis time
    (time.to_f * 1000).floor
  end

  def find_signature reference_code, pricing
    format="#{@apiKey}~#{@merchantId}~#{reference_code}~#{pricing}~#{@currency}"
    Digest::MD5.hexdigest format
  end

end