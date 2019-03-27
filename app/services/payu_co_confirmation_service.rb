class PayuCoConfirmationService
  include PayuUtils

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

  def initialize params
    @participant = Participant.find(params[:extra1])
    @state_pol = params[:state_pol]
    @estado = ESTADOS[@state_pol]
    @respuesta = RESPUESTAS[params[:response_code_pol]] || "Error en el pago: #{params[:response_message_pol]}"
    @referencia_payu = params[:reference_pol]
    @sign = params[:sign]
    @reference = params[:reference_sale] #reference_code
    @value = params[:value].to_f
    params[:description]
    @transaction_date=params[:transaction_date]
  end

  def confirm
    if is_valid_signature?
      update_participant
      sent_email_confirmation
    end
  end

  def sent_email_confirmation
    EventMailer.delay.payment_process_result(@participant,@result)
  end

  def is_valid_signature?
    sign = find_signature(@reference, @value, @state_pol)
    sign === @sign
  end

  def update_participant
    if @estado === :APROBADO
      @participant.status = "C" #confirmado
    end
    @result = "#{@estado.to_s} (#{@respuesta}),"\
      " con número de transacción en PayU: #{@referencia_payu}, por valor de: #{@value},"\
             " en la fecha de: #{@transaction_date}"
    @participant.notes += "\n\n Resultado del pago: #{@result}"

    @participant.save!
  end

end