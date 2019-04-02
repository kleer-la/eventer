class PayuCoResponseService
  include PayuUtils

  def initialize params
    @data_to_show = {}
    participant = Participant.find(params[:extra1])
    @transactionState = params[:transactionState]

    @data_to_show['Participante'] = "#{participant.fname} #{participant.lname}"
    @data_to_show['Estado del pago'] = ESTADOS[@transactionState]
    @data_to_show['Respuesta del sistema'] = RESPUESTAS[params[:polResponseCode]] || "Error en el pago: #{params[:message]}"
    @data_to_show['Referencia'] = params[:referenceCode]
    @data_to_show['Valor total'] = params[:TX_VALUE].to_f
    @data_to_show['Fecha'] =params[:processingDate]
    @data_to_show['Descripción'] =params[:description]

    @sign = params[:signature]
  end

  def response
    unless is_valid_signature?
      @data_to_show = {}
      @data_to_show["Error"] = " Hubo un error con la verificación de la firma"
      logger.info "sign Generated: #{@signGenerated}"
      logger.info "sign payu: #{@sign}"
    end
    @data_to_show
  end

  private

  def is_valid_signature?
    @signGenerated = find_signature(@data_to_show['Referencia'], @data_to_show['Valor total'], @transactionState)
    @signGenerated === @sign
  end



end