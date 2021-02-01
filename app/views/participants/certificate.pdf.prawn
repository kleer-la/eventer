if @page_size.nil? || (@page_size != "LETTER" && @page_size != "A4")
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "Solo puedes generar certificados en tamaño carta (LETTER) o A4 (A4). Por favor, contáctanos a entrenamos@kleer.la"
  end
elsif @certificate.nil? || (@verification_code != @certificate.verification_code)
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "El código de verificación #{@verification_code} no es válido. Por favor, contáctanos a entrenamos@kleer.la"
  end
elsif !@participant.is_confirmed_or_present?
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "#{@participant.fname} #{@participant.lname} no estuvo presente en este evento. Por favor, contáctanos a entrenamos@kleer.la"
  end
elsif @participant.event.trainer.signature_image.to_s == ''
  prawn_document(:page_layout => :landscape, :page_size => "LETTER") do |pdf|
    pdf.text "El trainer no tiene firma definida o no es accesible. Por favor, contáctanos a entrenamos@kleer.la"
  end
else

  prawn_document(:page_layout => :landscape, :page_size => @page_size) do |pdf|
    ParticipantsHelper::render_certificate( pdf, @certificate, @page_size )
  end

end
