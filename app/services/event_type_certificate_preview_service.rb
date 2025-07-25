# frozen_string_literal: true

class EventTypeCertificatePreviewService
  class Result
    attr_reader :success, :message, :data

    def initialize(success:, message: nil, data: {})
      @success = success
      @message = message
      @data = data
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  def self.prepare_preview_form(event_type, params = {})
    new(event_type).prepare_preview_form(params)
  end

  def self.generate_certificate_pdf(event_type, certificate_params)
    new(event_type).generate_certificate_pdf(certificate_params)
  end

  def initialize(event_type)
    @event_type = event_type
  end

  def prepare_preview_form(params = {})
    certificate_store = FileStoreService.create_s3
    images = certificate_store.background_list
    trainers = Trainer.where.not(signature_image: [nil, ''])
    certificate_values = load_preview_defaults(params)

    success_result(
      data: {
        images: images,
        trainers: trainers,
        certificate_values: certificate_values,
        page_size: 'LETTER'
      }
    )
  rescue StandardError => e
    failure_result("Error preparing preview form: #{e.message}")
  end

  def generate_certificate_pdf(certificate_params)
    # Create temporary event and participant for certificate generation
    event = build_preview_event(certificate_params)
    participant = build_preview_participant(event, certificate_params)

    # Generate certificate in the appropriate locale
    I18n.with_locale(event.event_type.lang) do
      certificate = ParticipantsHelper::Certificate.new(participant)
      certificate_store = FileStoreService.create_s3
      success_result(
        data: {
          certificate: certificate,
          participant: participant,
          event: event,
          certificate_store: certificate_store
        }
      )
    end
  rescue Aws::Errors::MissingCredentialsError
    failure_result('Missing AWS credentials - call support')
  rescue StandardError => e
    failure_result("Error generating certificate: #{e.message}")
  end

  private

  def load_preview_defaults(param_values)
    defaults = {
      certificate_background_image_url: @event_type.kleer_cert_seal_image.presence || ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE,
      certificate_city: 'Bogotá',
      certificate_name: 'Camilo Leonardo Padilla Restrepo',
      certificate_date: Date.today.prev_day.to_s,
      certificate_finish_date: Date.today.to_s,
      certificate_new_version: '1'
    }

    defaults.merge(param_values.to_h.symbolize_keys)
  end

  def build_preview_event(certificate_params)
    event = Event.new
    event.event_type = @event_type

    # Set trainers
    event.trainer = Trainer.find(certificate_params[:certificate_trainer1].to_i)
    if certificate_params[:certificate_trainer2].to_i.positive?
      event.trainer2 = Trainer.find(certificate_params[:certificate_trainer2].to_i)
    end

    # Set location and dates
    event.country = Country.find(certificate_params[:certificate_country].to_i)
    event.date = Date.strptime(certificate_params[:certificate_date])
    event.finish_date = Date.strptime(certificate_params[:certificate_finish_date])
    event.city = certificate_params[:certificate_city]

    # Set mode based on country
    event.mode = event.country.iso_code == 'OL' ? 'ol' : 'cl'

    # Configure event type settings
    event.event_type.new_version = (certificate_params[:certificate_new_version] == '1')
    event.event_type.kleer_cert_seal_image = if event.event_type.new_version
                                               certificate_params[:certificate_background_image_url]
                                             else
                                               certificate_params[:certificate_background_image_url].sub(
                                                 /-(A4|LETTER)/, ''
                                               )
                                             end

    # Set certification type
    event.event_type.is_kleer_certification = true if certificate_params[:certificate_kleer_cert] == '1'

    event
  end

  def build_preview_participant(event, certificate_params)
    participant = Participant.new
    participant.event = event
    participant.fname = certificate_params[:certificate_name]

    # Set participant status
    participant.attend!
    participant.certify! if certificate_params[:certificate_kleer_cert] == '1'

    participant
  end

  def success_result(message: nil, data: {})
    Result.new(success: true, message: message, data: data)
  end

  def failure_result(message)
    Result.new(success: false, message: message)
  end
end
