class PayuCoConfirmationService

  ESTADOS = {4 => :APROBADA, 6 => :DECLINADA, 5=> :EXPIRADA}
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
    @event = Event.find(params[:extra2])
    @participant = Participant.find[params[:extra1]]
    @estado = ESTADOS[params[:state_pol]]
    @respuesta = RESPUESTAS[params[:response_code_pol]] # tambien viene el response_message_pol
    @referencia_payu = params[:reference_pol]
    @sing = params[:sign]
    params[:reference_sale] #reference_code
    params[:value]
    params[:tax]
    params[:description]
    params[:date]
    params[:transaction_date]
    params[:email_buyer]#TODO validar contra el del formulario y actualizarlo

    # TODO validar sign de la transaccion
    # TODO actualizar participante
    # TODO enviar un mail de confirmacion de resultado
    # TODO responder status 200
  end

end