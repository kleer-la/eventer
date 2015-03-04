if @page_size != "LETTER" && @page_size != "A4"
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "Solo puedes generar certificados en tamaño carta (LETTER) o A4 (A4). Por favor, contáctanos a entrenamos@kleer.la"
  end
elsif @verification_code != @participant.verification_code
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "El código de verificación #{@verification_code} no es válido. Por favor, contáctanos a entrenamos@kleer.la"
  end  
elsif !@participant.is_confirmed_or_present?
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "#{@participant.fname} #{@participant.lname} no estuvo presente en este evento. Por favor, contáctanos a entrenamos@kleer.la"
  end
else

  rep_logo_path = "#{Rails.root}/app/assets/images/rep-logo-transparent.png"
  kleer_logo_path = "#{Rails.root}/app/assets/images/K-kleer_horizontal_negro_1color-01.png"
  trainer_signature_path = "#{Rails.root}/app/assets/images/firmas/" + @participant.event.trainer.signature_image


  prawn_document(:page_layout => :landscape, :page_size => @page_size) do |pdf|


    ParticipantsHelper::render_certificate( pdf, @certificate, @page_size )

   end

end