require 'dimensions'

module ParticipantsHelper
  class Certificate
    def initialize(participant)
      @participant=participant
      if !valid?
        raise ArgumentError,'No signature available for the first trainer'
      end
    end
    def valid?
      trainers[0].signature_image.present? 
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
    def is_kleer_certification?
      @participant.event.event_type.is_kleer_certification
    end
    def kleer_cert_seal_image
      @participant.event.event_type.kleer_cert_seal_image
    end
    def background_file
      kleer_cert_seal_image if v2021?
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
    def event_duration_hours
      @participant.event.event_type.duration
    end
    # Deprecated: online trainings are better described by hours
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
    def human_event_finish_date
      @participant.event.human_finish_date
    end
    def date
      @participant.event.human_date + ' ' + @participant.event.date.year.to_s
    end
    def trainer(t=0)
      @participant.event.trainers[t]&.name
    end
    def trainer_credentials(t=0)
      @participant.event.trainers[t]&.signature_credentials
    end
    def trainer_signature(t=0)
      @participant.event.trainers[t]&.signature_image
    end
    def trainers
        @participant.event.trainers
    end
    def v2021?
      kleer_cert_seal_image.to_s.include? '2021'
    end
    def description
      [ (Setting.get("CERTIFICATE_SCRUM_ALLIANCE") if is_csd_eligible?),
        (Setting.get("CERTIFICATE_KLEER") if is_kleer_certification? && !is_csd_eligible?),
        Setting.get("CERTIFICATE_BASE"),
        "Ha culminado con éxito el proceso de aprendizaje y adquisición de competencias."].find(&:present?)
    end
  end

  PageConfig = {
    :LogoPos => {"LETTER" => [-55, 610], "A4" => [-55, 590]},
    :SignPos => {"LETTER" => [500, 200], "A4" => [550, 190]},
    :OuterBox => {"LETTER" => [[-25, 565], 770, 585], "A4" => [[-25, 548], 820, 570]},
    :InnerBox => {"LETTER" => [[-20, 560], 760, 575], "A4" => [[-20, 543], 810, 560]}
  }

  class PdfCertificate
    include Prawn::View
    def initialize(doc, data, store=nil)
      @data= data
      @doc= doc
      font_families.update("Raleway" => {
        :normal => Rails.root.join("vendor/assets/fonts/Raleway-Regular.ttf"),
        :italic => Rails.root.join("vendor/assets/fonts/Raleway-Italic.ttf"),
        :bold => Rails.root.join("vendor/assets/fonts/Raleway-Bold.ttf"),
        :bold_italic => Rails.root.join("vendor/assets/fonts/Raleway-BoldItalic.ttf")
        })
        @store=store
        @kcolor= '39a2da'
        # fallback_fonts = ['Raleway']
        @top_right= {'A4'   => [400,500],
                  'LETTER' => [380,510] }[ @doc.page.size]
    end
    def document
      @doc
    end
    def background
      if @data.background_file.present?
        offset= {'A4'   => [-41,559],
               'LETTER' => [-38,576] }[ @doc.page.size]
        height= {'A4'   => 598,
                'LETTER' => 613 }[ @doc.page.size]
        image @store.read( @data.background_file, @doc.page.size), 
        at: offset, height: height
        # stroke_axis
      end
    end
    def event_name
      fill_color'000000'
      font "Raleway", style: :bold
      text_box @data.event_name,
                at: [0,@top_right[1]], width: @top_right[0], height: 90, :align => :left, 
                :size => 40,
                overflow: :shrink_to_fit
    end
    def participant_name
      font "Raleway"
      text_box @data.name,
                  at: [0,390], width: @top_right[0],  height: 30, :align => :left, 
                  :size => 26,
                  overflow: :shrink_to_fit
      line_width = 2
      stroke {horizontal_line 0,@top_right[0], at: 355 }
    end
    def certificate_description
      text_box @data.description,  
                  at: [0,340], width: @top_right[0], :align => :left, 
                  :size => 18,
                  overflow: :shrink_to_fit
    end
    def certificate_info
      text_box "<color rgb='#{@kcolor}'><b>MODALIDAD:</b></color> Online<br>"+
                   "<color rgb='#{@kcolor}'><b>REALIZADO:</b></color> #{@data.date}<br>"+
                   "<color rgb='#{@kcolor}'><b>DEDICACIÓN:</b></color> #{@data.event_duration_hours} hs",
                at: [0,250], :align => :left, 
                :size => 14,
                inline_format: true
    end
    def verification_code
      fill_color @kcolor
      text_box "Código verificación de la certificación:#{@data.verification_code}",
                at: [0,180], :align => :left, 
                :size => 10
    end
    def trainers
      trainer(0)
      trainer(1) if @data.trainer(1).present?
    end
    def trainer(t)
      trainer_width=130
      trainer_x = [@top_right[0]-trainer_width,
                   @top_right[0]-2*trainer_width-20][t]

      line_width = 1
      stroke {horizontal_line trainer_x,trainer_x+trainer_width, at: 60 }
      
      text_box "#{@data.trainer(t)}<br>#{@data.trainer_credentials(t)}",
                at: [trainer_x,55],  width: trainer_width, :align => :center, 
                :size => 12,
                inline_format: true
      signature_file= @store.read( @data.trainer_signature(t),nil, "certificate-signatures")
      if signature_file.present?
        image signature_file, at: [trainer_x, 60+100], height: 130
      end
    end
    def render
      background
      bounding_box [300,@top_right[1]], width: @top_right[0], height: 500 do
        event_name
        participant_name
        certificate_description
        certificate_info  
        verification_code
        trainers
      end
    end
  
  end

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

  def self.render_certificate( pdf, certificate, page_size, store= nil )
    if certificate.v2021?
      return PdfCertificate.new(pdf, certificate, store || CertificateStore.new).render
    end

    rep_logo_path = "#{Rails.root}/app/assets/images/rep-logo-transparent.png"
    kleer_logo_path = "#{Rails.root}/app/assets/images/K-kleer_horizontal_negro_1color-01.png"
    kleer_certification_seals_path = "#{Rails.root}/app/assets/images/seals/"

      if certificate.is_csd_eligible?
          pdf.image rep_logo_path, :width => 150, :position => :right
      elsif certificate.is_kleer_certification?
          this_seal_path = "#{kleer_certification_seals_path}/#{certificate.kleer_cert_seal_image}"
          pdf.image this_seal_path, :width => 150, :position => :right
      else
          pdf.move_down 100
      end

      pdf.image kleer_logo_path, :width => 300, :at => PageConfig[:LogoPos][page_size]

      pdf.move_down 50

      pdf.text "<b>Kleer</b> certifies that", :align => :center, :size => 14, :inline_format => true

      pdf.move_down 20

      pdf.text  "<b><i>#{certificate.name}</i></b>",
            :align => :center, :size => 48, :inline_format => true

      if certificate.is_kleer_certification?
        pdf.text "is awarded the designation", :align => :center, :size => 14
        pdf.move_down 10
        pdf.text "<b>#{certificate.event_name}</b>", :align => :center, :size => 24, :inline_format => true
        pdf.move_down 10
        pdf.text "on this day, #{certificate.human_event_finish_date} #{certificate.event_year}, for completing the prescribed requirements for this certification.", :align => :center, :size => 14
      else
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
      end

      pdf.move_down 10
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

  def self.generate_certificate( participant, page_size, store=nil )
    store ||= CertificateStore.new
    certificate = Certificate.new(participant)
    
    certificate_filename = store.absolute_path "#{participant.verification_code}p#{participant.id}-#{page_size}.pdf"
    Prawn::Document.generate(certificate_filename,
      :page_layout => :landscape, :page_size => page_size) do |pdf|
        self.render_certificate( pdf, certificate, page_size, store)
      end
#   store.write certificate_filename
    certificate_filename
  end

  def self.upload_certificate( certificate_filename, access_key_id: nil, secret_access_key: nil)

  	s3 = AWS::S3.new(
  		:access_key_id => access_key_id || ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
  		:secret_access_key => secret_access_key || ENV['KEVENTER_AWS_SECRET_ACCESS_KEY'])

  	key = File.basename(certificate_filename)
    bucket = s3.buckets['Keventer']
  	bucket.objects["certificates/#{key}"].write(:file => certificate_filename )
  	bucket.objects["certificates/#{key}"].acl = :public_read

  	"https://s3.amazonaws.com/Keventer/certificates/#{key}"
  end

  class CertificateStore
    def self.createNull
      CertificateStore.new.init_null
    end
    def initialize(access_key_id: nil, secret_access_key: nil)
      s3 = AWS::S3.new(
        :access_key_id => access_key_id || ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
        :secret_access_key => secret_access_key || ENV['KEVENTER_AWS_SECRET_ACCESS_KEY'])
      @bucket = s3.buckets['Keventer']
    end
    def objects(key)
      if @bucket.present?
        @bucket.objects[key]
      else
        StoreObject::createNull     
      end
    end
    def init_null
      @bucket = nil
      self
    end

    def absolute_path basename
      temp_dir = "#{Rails.root}/tmp"
      Dir.mkdir( temp_dir ) unless Dir.exist?( temp_dir )
      temp_dir+'/'+basename
    end
    def write(certificate_filename)
      key = File.basename(certificate_filename)
      objects("certificates/#{key}").write(:file => certificate_filename )
      objects("certificates/#{key}").acl = :public_read

      "https://s3.amazonaws.com/Keventer/certificates/#{key}"
    end
    def read(filename, suffix, folder='certificate-images')
      suffix = ('-' + suffix) if suffix.present?
      key = File.basename(filename,'.*') + suffix.to_s + File.extname(filename)

      if !objects("#{folder}/#{key}").exists?
        return nil
      end
      tmp_filename= absolute_path filename
      File.open(tmp_filename, 'wb') do |file|
        objects("#{folder}/#{key}").read do |chunk|
          file.write(chunk)
        end
      end
      tmp_filename
    end
  end

  class StoreObject
    attr_writer :key, :acl
    def self.createNull
        StoreObject.new
    end
    def read
      yield File.open("./spec/views/participant/base2021-A4.png").read
    end
    def write n
    end
    def exists?
      true
    end
  end
end
