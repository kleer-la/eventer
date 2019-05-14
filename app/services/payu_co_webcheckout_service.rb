require 'digest'
require 'date'

class PayuCoWebcheckoutService
  include PayuUtils

  def initialize
    @iva = 19
  end

  def prepare_webcheckout event, participant
    pricing = find_pricing event
    iva = find_iva(pricing)
    time = Time.now
    reference_plain = "Kleer: #{event.name}, #{participant.fname} #{participant.lname}, #{pricing}, #{time}"
    webcheckout_data = {}
    webcheckout_data[:action]=WEB_CHECKOUT_URL
    webcheckout_data[:merchantId]= MERCHANT_ID
    webcheckout_data[:accountId]= ACCOUNT_ID
    webcheckout_data[:description]= "Pago de #{participant.fname} #{participant.lname} por #{event.event_type.name} de Kleer"
    webcheckout_data[:referenceCode]= get_time_in_milis(time)
    webcheckout_data[:amount]= pricing
    webcheckout_data[:tax]= iva
    webcheckout_data[:taxReturnBase]= pricing - iva
    webcheckout_data[:currency]= CURRENCY
    webcheckout_data[:signature]= find_signature(get_time_in_milis(time), pricing)
    webcheckout_data[:test]= TEST
    webcheckout_data[:buyerEmail]= participant.email
    webcheckout_data[:buyerFullName]= "#{participant.fname} #{participant.lname}"
    webcheckout_data[:telephone]= participant.phone
    webcheckout_data[:responseUrl]= RESPONSE_URL
    webcheckout_data[:confirmationUrl]= CONFIRMATION_URL
    webcheckout_data[:extra1]= participant.id
    webcheckout_data[:extra2]= event.id
    webcheckout_data[:extra3]= reference_plain
    webcheckout_data
  end

  private

  def find_pricing event
    end_eb = Date.parse(event.eb_end_date.strftime('%Y-%m-%d'))
    if end_eb  >= Date.today
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



end