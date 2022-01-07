# frozen_string_literal: true

require 'dimensions'

module ParticipantsHelper
  DEFAULT_BACKGROUND_IMAGE = 'base2021.png'
  CERTIFICATE_SCRUM_ALLIANCE = 'CERTIFICATE_SCRUM_ALLIANCE'
  CERTIFICATE_KLEER = 'CERTIFICATE_KLEER'
  CERTIFICATE_NONE = 'CERTIFICATE_NONE'

  def self.validate_page_size(page_size)
    return unless page_size.nil? || (page_size != 'LETTER' && page_size != 'A4')

    'Solo puedes generar certificados en tamaño carta (LETTER) o A4 (A4).
    Por favor, contáctanos a entrenamos@kleer.la'
  end

  def self.validate_event(event)
    'Trainer sin firma o no es accesible. Por favor, contáctanos a entrenamos@kleer.la' unless
      event.trainer.signature_image.present?
  end

  def self.validation_participant(participant, verification_code)
    if verification_code != participant.verification_code
      "El código de verificación #{@verification_code} no es válido. Por favor, contáctanos a entrenamos@kleer.la"
    elsif !participant.could_receive_certificate?
      'El participante no puede recibir un certificado (Confirmado, presente o certificado).
      Por favor, contáctanos a entrenamos@kleer.la'
    end
  end

  class Certificate
    def initialize(participant)
      @participant = participant
      raise ArgumentError, 'No signature available for the first trainer' unless valid?

      seal
    end

    def valid?
      trainers[0].signature_image.present?
    end

    def name
      "#{@participant.fname} #{@participant.lname}"
    end

    def verification_code
      @participant.verification_code
    end

    def csd_eligible?
      @participant.event.event_type.csd_eligible
    end

    def kleer_certification?
      @participant.event.event_type.is_kleer_certification
    end

    def seal
      @cert_image = ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
      seal = @participant.event.event_type.kleer_cert_seal_image
      @cert_image = seal if seal.present? && (!kleer_certification? || @participant.certified?)
    end

    def background_file
      @cert_image unless foreground?
    end

    def foreground_file
      @cert_image if foreground?
    end

    def certified?
      @participant.certified?
    end

    def foreground?
      @cert_image.include? 'fg'
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
      if @participant.event.online?
        'an OnLine course'
      else
        "#{@participant.event.city}, #{@participant.event.country.name}"
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
      if (d % 8).positive? || @participant.event.online?
        unit = 'hour'
      else
        unit = 'day'
        d /= 8
      end
      plural = 's' unless d == 1
      "#{d} #{unit}#{plural}"
    end

    def human_event_finish_date
      @participant.event.human_finish_date
    end

    def date
      "#{@participant.event.human_date} #{@participant.event.date.year}"
    end

    def trainer(t_ord)
      @participant.event.trainers[t_ord]&.name
    end

    def trainer_credentials(t_ord)
      @participant.event.trainers[t_ord]&.signature_credentials
    end

    def trainer_signature(t_ord)
      @participant.event.trainers[t_ord]&.signature_image
    end

    def trainers
      @participant.event.trainers
    end

    def description
      [
        (Setting.get(CERTIFICATE_KLEER)          if certified? && kleer_certification?),
        (Setting.get(CERTIFICATE_SCRUM_ALLIANCE) if certified? && csd_eligible?),
        Setting.get(CERTIFICATE_NONE),
        'Ha culminado con éxito el proceso de aprendizaje y adquisición de competencias.'
      ].find(&:present?)
    end
  end

  class PdfCertificate
    include Prawn::View
    def initialize(doc, data, store = nil)
      @data = data
      @doc = doc
      font_update
      @store = store
      @kcolor = '39a2da'
      @top_right = { 'A4' => [400, 500],
                     'LETTER' => [380, 510] }[ @doc.page.size]
    end

    def font_update
      font_families.update(
        'Raleway' => {
          normal: Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf'),
          italic: Rails.root.join('vendor/assets/fonts/Raleway-Italic.ttf'),
          bold: Rails.root.join('vendor/assets/fonts/Raleway-Bold.ttf'),
          bold_italic: Rails.root.join('vendor/assets/fonts/Raleway-BoldItalic.ttf')
        }
      )
    end

    def document
      @doc
    end

    def fill_image(img_file)
      offset = { 'A4' => [-41, 559],
                 'LETTER' => [-38, 576] }[ @doc.page.size]
      height = { 'A4' => 598,
                 'LETTER' => 613 }[ @doc.page.size]
      bk_image = @store.read(img_file, @doc.page.size)
      image bk_image, at: offset, height: height
    end

    def event_name
      fill_color '000000'
      font 'Raleway', style: :bold
      text_box @data.event_name,
               at: [0, @top_right[1]], width: @top_right[0], height: 90, align: :left,
               size: 40,
               overflow: :shrink_to_fit
    end

    def participant_name
      font 'Raleway'
      text_box @data.name,
               at: [0, 390], width: @top_right[0], height: 30, align: :left,
               size: 26,
               overflow: :shrink_to_fit
      stroke { horizontal_line 0, @top_right[0], at: 355 }
    end

    def certificate_description
      text_box @data.description,
               at: [0, 340], width: @top_right[0], align: :left,
               size: 18,
               overflow: :shrink_to_fit
    end

    def certificate_info
      text_box "<color rgb='#{@kcolor}'><b>MODALIDAD:</b></color>#{@data.place}<br>" \
               "<color rgb='#{@kcolor}'><b>REALIZADO:</b></color> #{@data.date}<br>" \
               "<color rgb='#{@kcolor}'><b>DEDICACIÓN:</b></color> #{@data.event_duration_hours} hs",
               at: [0, 250], align: :left,
               size: 14,
               inline_format: true
    end

    def verification_code
      fill_color @kcolor
      text_box "Código de verificación de la certificación:#{@data.verification_code}",
               at: [0, 180], align: :left,
               size: 10
    end

    def trainers
      trainer(0)
      trainer(1) if @data.trainer(1).present? && @data.trainer_signature(1).present?
    end

    def trainer(t_ord)
      trainer_width = 130
      trainer_x = [@top_right[0] - trainer_width,
                   @top_right[0] - 2 * trainer_width - 20][t_ord]

      stroke { horizontal_line trainer_x, trainer_x + trainer_width, at: 60 }

      text_box "#{@data.trainer(t_ord)}<br>#{@data.trainer_credentials(t_ord)}",
               at: [trainer_x, 55], width: trainer_width, align: :center,
               size: 12,
               inline_format: true
      signature_file = @store.read(@data.trainer_signature(t_ord), nil, 'certificate-signatures')
      image signature_file, at: [trainer_x, 60 + 100], height: 130 if signature_file.present?
    end

    def render
      # stroke_axis
      fill_image(@data.background_file) if @data.background_file.present?
      bounding_box [300, @top_right[1]], width: @top_right[0], height: 500 do
        event_name
        participant_name
        certificate_description
        certificate_info
        verification_code
        trainers
      end
      fill_image(@data.foreground_file) if @data.foreground_file.present?
    end
  end

  def self.render_certificate(pdf, certificate, _page_size, store)
    PdfCertificate.new(pdf, certificate, store).render
  end

  def self.generate_certificate(participant, page_size, store)
    certificate = Certificate.new(participant)

    certificate_filename = store.tmp_path "#{participant.verification_code}p#{participant.id}-#{page_size}.pdf"
    Prawn::Document.generate(certificate_filename,
                             page_layout: :landscape, page_size: page_size) do |pdf|
      render_certificate(pdf, certificate, page_size, store)
    end
    certificate_filename
  end

  def self.upload_certificate(certificate_filename, access_key_id: nil, secret_access_key: nil)
    resource = s3_resource(access_key_id, secret_access_key)
    key = File.basename(certificate_filename)
    bucket = resource.bucket('Keventer')
    object = bucket.object("certificates/#{key}")
    object.upload_file(certificate_filename)
    object.acl.put({ acl: 'public-read' })

    "https://s3.amazonaws.com/Keventer/certificates/#{key}"
  end

  def self.s3_resource(access_key_id, secret_access_key)
    client = Aws::S3::Client.new(
      access_key_id: access_key_id || ENV['KEVENTER_AWS_ACCESS_KEY_ID'],
      secret_access_key: secret_access_key || ENV['KEVENTER_AWS_SECRET_ACCESS_KEY']
    )
    Aws::S3::Resource.new(client: client)
  end
end
