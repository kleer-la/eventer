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

  is_csd_eligible = @participant.event.event_type.csd_eligible

  prawn_document(:page_layout => :landscape, :page_size => @page_size) do |pdf|

    if is_csd_eligible
        pdf.image rep_logo_path, :width => 150, :position => :right
    else
        pdf.move_down 100
    end

    if @page_size == "LETTER"
  	 pdf.image kleer_logo_path, :width => 300, :at => [-55, 610]
    elsif @page_size == "A4"
  	 pdf.image kleer_logo_path, :width => 300, :at => [-55, 590]
    end 

    pdf.move_down 50

    pdf.text "<b>Kleer</b> certifies that", :align => :center, :size => 14, :inline_format => true
   
    pdf.move_down 20

    pdf.text 	"<b><i>#{@participant.fname} #{@participant.lname}</i></b>", 
    			:align => :center, :size => 64, :inline_format => true

    pdf.text "attended the course named", :align => :center, :size => 14

    pdf.move_down 10

    pdf.text "<b><i>#{@participant.event.event_type.name}</i></b>", :align => :center, :size => 24, :inline_format => true

    pdf.move_down 10

    pdf.text 	"delivered in <b>#{@participant.event.city}, #{@participant.event.country.name}</b>, " +
    			"on <b>#{@participant.event.human_date} #{@participant.event.date.year}</b>, " +
                "with a duration of #{@participant.event.duration} days.",
    			:align => :center, :size => 14, :inline_format => true 

    if is_csd_eligible
        pdf.text    "This course has been approved by the <b>Scrum Alliance</b> as a CSD-eligible one,",
                    :align => :center, :size => 14, :inline_format => true

        pdf.text    "therefore valid for the <b>Certified Scrum Developer</b> certification.",
                    :align => :center, :size => 14, :inline_format => true
    end

    pdf.text    "<i>Certificate verification code: #{@participant.verification_code}.</i>",
                :align => :center, :size => 9, :inline_format => true         

    if @page_size == "LETTER"
        signature_position = [500, 160]
    elsif @page_size == "A4"
        signature_position = [550, 150]
    end 

    pdf.bounding_box(signature_position, :width => 200, :height => 120) do
        #pdf.transparent(0.5) { pdf.stroke_bounds }
        pdf.image trainer_signature_path, :position => :center, :scale => 0.7
        pdf.text "<b>#{@participant.event.trainer.name}</b>", :align => :center, :size => 14, :inline_format => true
        pdf.text "#{@participant.event.trainer.signature_credentials}", :align => :center, :size => 14
    end

    if is_csd_eligible
        pdf.text    "Kleer is a Scrum Alliance Registered Education Provider. " +
                    "SCRUM ALLIANCE REP(SM) is a service mark of Scrum Alliance, Inc. " +
                    "Any unauthorized use is strictly prohibited.", :valign => :bottom, :size => 9
    end

    pdf.line_width = 3

    pdf.stroke do
    	if @page_size == "LETTER"
    		pdf.rectangle [-25, 565], 770, 585
    	elsif @page_size == "A4"
    		pdf.rectangle [-25, 548], 820, 570
    	end
    end

    pdf.line_width = 1

    pdf.stroke do
    	if @page_size == "LETTER"
    		pdf.rectangle [-20, 560], 760, 575
    	elsif @page_size == "A4"
    	    pdf.rectangle [-20, 543], 810, 560
    	end
    end

  end

end