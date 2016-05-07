require 'dimensions'

module ParticipantsHelper
  class Certificate
    def initialize(participant)
      @participant=participant
    end
    def name
      @participant.fname + ' ' + @participant.lname
    end
    def verification_code
      @participant.verification_code
    end
    def is_csd_eligible?
      @participant.event.event_type.csd_eligible
    end
    def event_name
      @participant.event.event_type.name
    end
    def event_city
      @participant.event.city
    end
    def event_country
      @participant.event.country.name
    end
    def place
      if @participant.event.is_online?
        'an OnLine course'
      else
        @participant.event.city + ', ' + @participant.event.country.name
      end
    end
    def event_date
      @participant.event.human_date
    end
    def event_year
      @participant.event.date.year.to_s
    end
    def event_duration
      d = @participant.event.event_type.duration
      if (d % 8)>0 || @participant.event.is_online?
        unit = "hour"
      else
        unit = "day"
        d /= 8
      end
      plural = "s" unless d==1
      "#{d} #{unit}#{plural}"
    end
    def trainer
      @participant.event.trainers[0].name
    end
    def trainer_credentials
      @participant.event.trainers[0].signature_credentials
    end
    def trainer_signature
      @participant.event.trainers[0].signature_image
    end
    def trainers
        @participant.event.trainers
    end
  end

  PageConfig = {
    :LogoPos => {"LETTER" => [-55, 610], "A4" => [-55, 590]},
    :SignPos => {"LETTER" => [500, 200], "A4" => [550, 190]},
    :OuterBox => {"LETTER" => [[-25, 565], 770, 585], "A4" => [[-25, 548], 820, 570]},
    :InnerBox => {"LETTER" => [[-20, 560], 760, 575], "A4" => [[-20, 543], 810, 560]}
  }

  def self.render_signature(pdf, certificate, page_size)
    trainers= certificate.trainers
    signature_position = PageConfig[:SignPos][page_size].dup
    (0...trainers.count).each {|i|
      render_one_signature(pdf, signature_position, trainers[i])
      signature_position[0] -= 205 # ancho + 5
    }
  end

  def self.render_one_signature(pdf, pos, trainer)
    if trainer.signature_image.to_s==''
      return
    end
    trainer_signature_path = "#{Rails.root}/app/assets/images/firmas/" + trainer.signature_image
    delta=((200-30)-Dimensions.height(trainer_signature_path))*0.7
    pdf.bounding_box([pos[0],pos[1]-delta], :width => 200, :height => 120) do
        pdf.image trainer_signature_path, :position => :center, :scale => 0.7
        pdf.text "<b>#{trainer.name}</b>", :align => :center, :size => 14, :inline_format => true
        pdf.text "#{trainer.signature_credentials}", :align => :center, :size => 14
    end
  end

  def self.render_certificate( pdf, certificate, page_size )
    rep_logo_path = "#{Rails.root}/app/assets/images/rep-logo-transparent.png"
    kleer_logo_path = "#{Rails.root}/app/assets/images/K-kleer_horizontal_negro_1color-01.png"

      if certificate.is_csd_eligible?
          pdf.image rep_logo_path, :width => 150, :position => :right
      else
          pdf.move_down 100
      end

      pdf.image kleer_logo_path, :width => 300, :at => PageConfig[:LogoPos][page_size]

      pdf.move_down 50

      pdf.text "<b>Kleer</b> certifies that", :align => :center, :size => 14, :inline_format => true

      pdf.move_down 20

      pdf.text  "<b><i>#{certificate.name}</i></b>",
            :align => :center, :size => 48, :inline_format => true

      pdf.text "attended the course named", :align => :center, :size => 14

      pdf.move_down 10

      pdf.text    "<b><i>#{certificate.event_name}</i></b>",
                  :align => :center, :size => 24, :inline_format => true

      pdf.move_down 10

      pdf.text  "delivered in <b>#{certificate.place}</b>, " +
            "on <b>#{certificate.event_date} #{certificate.event_year}</b>, " +
                  "with a duration of #{certificate.event_duration}.",
            :align => :center, :size => 14, :inline_format => true

      if certificate.is_csd_eligible?
          pdf.text    "This course has been approved by the <b>Scrum Alliance</b> as a CSD-eligible one,",
                      :align => :center, :size => 14, :inline_format => true

          pdf.text    "therefore valid for the <b>Certified Scrum Developer</b> certification.",
                      :align => :center, :size => 14, :inline_format => true
      end

      pdf.text    "<i>Certificate verification code: #{certificate.verification_code}.</i>",
                  :align => :center, :size => 9, :inline_format => true

      self.render_signature(pdf, certificate, page_size)

      if certificate.is_csd_eligible?
          pdf.text    "Kleer is a Scrum Alliance Registered Education Provider. " +
                      "SCRUM ALLIANCE REP(SM) is a service mark of Scrum Alliance, Inc. " +
                      "Any unauthorized use is strictly prohibited.", :valign => :bottom, :size => 9
      end

      pdf.line_width = 3
      pdf.stroke {pdf.rectangle *PageConfig[:OuterBox][page_size] }

      pdf.line_width = 1
      pdf.stroke {pdf.rectangle *PageConfig[:InnerBox][page_size] }

  end

  def self.generate_certificate( participant, page_size )
    temp_dir = "#{Rails.root}/tmp"
    Dir.mkdir( temp_dir ) unless Dir.exist?( temp_dir )

    certificate_filename = "#{temp_dir}/#{participant.verification_code}p#{participant.id}-#{page_size}.pdf"

    Prawn::Document.generate(certificate_filename,
      :page_layout => :landscape, :page_size => page_size) do |pdf|
      self.render_certificate( pdf, Certificate.new(participant), page_size )
    end

    certificate_filename
  end

  def self.upload_certificate( certificate_filename )

  	s3 = AWS::S3.new(
  		:access_key_id => ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
  		:secret_access_key => ENV['KEVENTER_AWS_SECRET_ACCESS_KEY'])

  	key = File.basename(certificate_filename)
  	bucket = s3.buckets['Keventer']
  	bucket.objects["certificates/#{key}"].write(:file => certificate_filename )
  	bucket.objects["certificates/#{key}"].acl = :public_read

  	"https://s3.amazonaws.com/Keventer/certificates/#{key}"
  end

end
