class PayuCoResponseService
  include PayuUtils

  #https://localhost:3000/events/payuco/response?merchantId=508029&merchant_name=Test+PayU+Test+comercio&merchant_address=Av+123+Calle+12&telephone=7512354&merchant_url=http%3A%2F%2Fpruebaslapv.xtrweb.com&transactionState=4&lapTransactionState=APPROVED&message=APPROVED&referenceCode=Agile+%26+Scrum+Coaching%2C+yamit+cardenas%2C+1000000.0%2C+2019-04-02+16%3A12%3A00+%2B0000&reference_pol=845486395&transactionId=6408a8a5-31c8-4caf-8f8f-712cca836bb7&description=Pago+por+Agile+%26+Scrum+Coaching&trazabilityCode=00000000&cus=00000000&orderLanguage=es&extra1=20&extra2=1239&extra3=&polTransactionState=4&signature=aa3f3c88260488cb0ed0d8fa97cac457&polResponseCode=1&lapResponseCode=APPROVED&risk=&polPaymentMethod=10&lapPaymentMethod=VISA&polPaymentMethodType=2&lapPaymentMethodType=CREDIT_CARD&installmentsNumber=1&TX_VALUE=1000000.00&TX_TAX=159663.87&currency=COP&lng=es&pseCycle=&buyerEmail=yamit.cardenas%40kleer.la&pseBank=&pseReference1=&pseReference2=&pseReference3=&authorizationCode=00000000&processingDate=2019-04-02

  def initialize params
    @data_to_show = {}
    participant = Participant.find(params[:extra1])
    @transactionState = params[:transactionState]

    @data_to_show['Participante'] = "#{participant.fname} #{participant.lname}"
    @data_to_show['Estado del pago'] = ESTADOS[@transactionState]
    @data_to_show['Respuesta de PayU'] = RESPUESTAS[params[:polResponseCode]] || "Error en el pago: #{params[:message]}"
    @data_to_show['Referencia'] = params[:referenceCode]
    @data_to_show['ReferenciaDetallada'] = params[:extra3]
    @data_to_show['Valor total'] = params[:TX_VALUE].to_f
    @data_to_show['Fecha'] =params[:processingDate]
    @data_to_show['Descripción'] =params[:description]

    @sign = params[:signature]
  end

  def response
    unless is_valid_signature?
      @data_to_show = {}
      @data_to_show["Error"] = " Hubo un error con la verificación de la firma"
      puts "sign Generated: #{@signGenerated}"
      puts "sign payu: #{@sign}"
    end
    @data_to_show
  end

  private

  def is_valid_signature?
    @signGenerated = find_signature(@data_to_show['Referencia'], @data_to_show['Valor total'], @transactionState)
    @signGenerated === @sign
  end



end