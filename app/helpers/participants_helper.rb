# frozen_string_literal: true

require 'dimensions'

module ParticipantsHelper
  DEFAULT_BACKGROUND_IMAGE = 'base2021.png'
  DEFAULT_BACKGROUND_IMAGE_V2 = 'certificado-generico.jpg'
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

    def new_version
      @participant.event.event_type.new_version
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

    def kleer_certification_for_this_participant?
      kleer_certification? && @participant.certified?
    end

    def use_this_seal
      seal = @participant.event.event_type.kleer_cert_seal_image
      if seal.present? && (kleer_certification_for_this_participant? || !kleer_certification?)
        seal
      else
        nil
      end
    end

    def seal
      # @cert_image = ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
      # @cert_image = ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE_V2 if new_version
      @cert_image = ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE_V2

      @cert_image = use_this_seal || @cert_image
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
    def place_v2
      if @participant.event.online?
        "#{I18n.t('certificate.how')}: <b>Online</b>"
      else
        "<b>#{@participant.event.city}, #{@participant.event.country.name}</b>"
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

    def finish_date_v2
      d = [@participant.event.finish_date, @participant.event.date].compact
      I18n.l d[0], format: :short_with_year
    end

    def finish_date
      @participant.event.finish_date
    end

    def date
      @participant.event.human_long_date
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
        I18n.t('certificate.dod')
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
      @verification_code_y =  180
    end

    def font_update
      font_families.update(
        'Raleway' => {
          normal: Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf'), # TODO: replace with regular
          regular: Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf'),
          thin: Rails.root.join('vendor/assets/fonts/Raleway-Thin.ttf'),
          light: Rails.root.join('vendor/assets/fonts/Raleway-Light.ttf'),
          italic: Rails.root.join('vendor/assets/fonts/Raleway-Italic.ttf'),
          bold: Rails.root.join('vendor/assets/fonts/Raleway-Bold.ttf'),
          semibold: Rails.root.join('vendor/assets/fonts/Raleway-SemiBold.ttf'),
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
      text_box "<color rgb='#{@kcolor}'><b>#{I18n.t('certificate.how').upcase}: </b></color>#{@data.place}<br>" \
               "<color rgb='#{@kcolor}'><b>#{I18n.t('certificate.date').upcase}:</b></color> #{@data.date}<br>" \
               "<color rgb='#{@kcolor}'><b>#{I18n.t('certificate.length').upcase}:</b></color> #{@data.event_duration_hours} hs",
               at: [0, 250], align: :left,
               size: 14,
               inline_format: true
    end

    def verification_code
      fill_color '000000' #@kcolor
      text_box I18n.t('certificate.code', code: @data.verification_code),
               at: [0, @verification_code_y], align: :left,
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

    def body(&block)
      bounding_box [300, @top_right[1]], width: @top_right[0], height: 500 do
        yield if block_given?
      end
    end

    def render
      # stroke_axis
      fill_image(@data.background_file) if @data.background_file.present?
      body do
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
  # =---------------------------------------------------------------------
  #  New version
  class PdfCertificateV2 < PdfCertificate
    def initialize(doc, data, store = nil)
      super(doc, data, store)
      @kcolor = '606060'
      @top_right = [370, 500]
      @participant_y = 378
      @certificate_description_y = @participant_y - 60
      @info_y = 252
    end
    def event_name
      fill_color '000000'
      font 'Raleway', style: :bold
      text_box @data.event_name,
               at: [0, @top_right[1]], width: @top_right[0], height: 75, align: :left,
               size: 40,
               overflow: :shrink_to_fit
    end

    def participant_name
      font 'Raleway', style: :light
      text_box 'CERTIFICADO OTORGADO A',
               at: [0, @participant_y + 14], width: @top_right[0], height: 20, align: :left,
               size: 12
      font 'Raleway', style: :semibold
      text_box @data.name,
               at: [0, @participant_y], width: @top_right[0] + 250, height: 50, align: :left,
               size: 36,
               overflow: :shrink_to_fit
      # stroke { horizontal_line 0, @top_right[0], at: 355 }
    end

    def certificate_description
      font 'Raleway', style: :regular
      fill_color @kcolor
      text_box @data.description,
               at: [0, @certificate_description_y], width: @top_right[0], align: :left,
               size: 12,
               overflow: :shrink_to_fit
    end

    def rounded_rectangle_text(x, y, padding, size, text)
      # fill_color '90' * 3

      # text_width = width_of(text, size: size)
      # fill_rounded_rectangle([x, y+padding], text_width, size + 14, padding)

      text_box "<color rgb='FFFFFF'>#{text}<br>",
        at: [padding, y], align: :left,
        size: 13,
        inline_format: true
    end
  
    def certificate_info
      font 'Raleway', style: :regular
      margin = 5

      rounded_rectangle_text(0, @info_y, margin, 13, @data.place_v2)

      text_box "<color rgb='#{@kcolor}'>#{I18n.t('certificate.finish_date')}: </color> <b>#{@data.finish_date_v2}</b> | " \
               "<color rgb='#{@kcolor}'>#{I18n.t('certificate.length')}: </color> <b>#{@data.event_duration_hours} hs</b>",
               at: [margin, @info_y - 32], align: :left,
               size: 13,
               inline_format: true
    end

    def fill_image(img_file)
      offset = [-36, 576]
      height = 613
      bk_image = @store.read(img_file, nil)
      image bk_image, at: offset, height: height
    end
    def body(&block)
      bounding_box [45, @top_right[1]], width: @top_right[0], height: 500 do
        yield if block_given?
      end
    end
    def trainer(t_ord)
      trainer_width = 132 * 1.3
      trainer_height = 69 * 1.3
      trainer_y = 31
      trainer_x = [@top_right[0] - trainer_width - 10,
                   @top_right[0] - 2 * trainer_width - 20][t_ord]

      stroke { horizontal_line trainer_x, trainer_x + trainer_width, at: trainer_y }

      font 'Raleway', style: :thin
      fill_color '000000'
      text_box "#{@data.trainer(t_ord)}<br>#{@data.trainer_credentials(t_ord)}",
               at: [trainer_x, trainer_y - 5], width: trainer_width, align: :center,
               size: 11,
               inline_format: true
      signature_file = @store.read(@data.trainer_signature(t_ord), nil, 'certificate-signatures')
      image signature_file, at: [trainer_x, trainer_y + trainer_height -10], height: trainer_height if signature_file.present?
    end
  end
  class PdfKleerCertificateV2 < PdfCertificateV2
    def initialize(doc, data, store = nil)
      super(doc, data, store)
      @participant_y = 350
      @certificate_description_y = @participant_y - 50
      @info_y = 232
      @verification_code_y = 170
    end
  end

  def self.certificate_factory(pdf, certificate, store)
    if certificate.kleer_certification_for_this_participant?
      PdfKleerCertificateV2.new(pdf, certificate, store)
    else
      PdfCertificateV2.new(pdf, certificate, store)
    end
  end

  def self.render_certificate(pdf, certificate, _page_size, store)
    certificate_factory(pdf, certificate, store).render
  end

  def self.generate_certificate(participant, page_size, store)
    certificate_filename = store.tmp_path "#{participant.verification_code}p#{participant.id}-#{page_size}.pdf"

    I18n.with_locale(participant.event.event_type.lang) do
      certificate = Certificate.new(participant)

      Prawn::Document.generate(certificate_filename,
                              page_layout: :landscape, page_size: page_size) do |pdf|
        render_certificate(pdf, certificate, page_size, store)
      end
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

  def quantity_list
    seat_text = []
    5.times {seat_text.push I18n.t('formtastic.button.participant.seats') }
    seat_text.push I18n.t('formtastic.button.participant.seat')

    (1..6).reduce([]) do |ac, qty|
      price = @event.price(qty, DateTime.now)
      formatted_price = number_to_currency(@event.price(qty, DateTime.now),
        precision: 0, delimiter: '.', unit: '')
      formatted_total = number_to_currency(price * qty,
        precision: 0, delimiter: '.', unit: '')

      ac << ["#{qty} #{seat_text.pop} x #{formatted_price} #{@event.currency_iso_code} = #{formatted_total} #{@event.currency_iso_code}", qty]
    end
  end


end
