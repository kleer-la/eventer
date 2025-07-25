# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventTypeCertificatePreviewService do
  let(:event_type) { create(:event_type, name: 'Test Course', lang: 'es') }
  let(:trainer1) { create(:trainer, signature_image: 'signature1.png') }
  let(:trainer2) { create(:trainer, signature_image: 'signature2.png') }
  let(:country) { create(:country, iso_code: 'AR') }

  before do
    # Mock FileStoreService
    file_store_mock = double('FileStoreService')
    allow(FileStoreService).to receive(:create_s3).and_return(file_store_mock)
    allow(file_store_mock).to receive(:background_list).and_return(['image1.jpg', 'image2.jpg'])

    # Mock ParticipantsHelper::Certificate
    allow(ParticipantsHelper::Certificate).to receive(:new).and_return(double('Certificate'))
  end

  describe '.prepare_preview_form' do
    context 'when successful' do
      it 'returns form data with defaults' do
        result = described_class.prepare_preview_form(event_type)

        expect(result).to be_success
        expect(result.data[:images]).to eq(['image1.jpg', 'image2.jpg'])
        expect(result.data[:trainers]).to be_an(ActiveRecord::Relation)
        expect(result.data[:certificate_values]).to be_a(Hash)
        expect(result.data[:page_size]).to eq('LETTER')
      end

      it 'merges provided parameters with defaults' do
        params = { certificate_city: 'Madrid', certificate_name: 'John Doe' }
        result = described_class.prepare_preview_form(event_type, params)

        expect(result).to be_success
        expect(result.data[:certificate_values][:certificate_city]).to eq('Madrid')
        expect(result.data[:certificate_values][:certificate_name]).to eq('John Doe')
        expect(result.data[:certificate_values][:certificate_date]).to eq(Date.today.prev_day.to_s)
      end

      it 'includes default values' do
        result = described_class.prepare_preview_form(event_type)

        values = result.data[:certificate_values]
        expect(values[:certificate_city]).to eq('Bogotá')
        expect(values[:certificate_name]).to eq('Camilo Leonardo Padilla Restrepo')
        expect(values[:certificate_new_version]).to eq('1')
      end
    end

    context 'when FileStoreService fails' do
      before do
        allow(FileStoreService).to receive(:create_s3).and_raise(StandardError, 'AWS Error')
      end

      it 'returns failure result' do
        result = described_class.prepare_preview_form(event_type)

        expect(result).to be_failure
        expect(result.message).to include('Error preparing preview form')
      end
    end
  end

  describe '.generate_certificate_pdf' do
    let(:certificate_params) do
      {
        certificate_trainer1: trainer1.id.to_s,
        certificate_trainer2: trainer2.id.to_s,
        certificate_country: country.id.to_s,
        certificate_date: '2024-01-15',
        certificate_finish_date: '2024-01-16',
        certificate_city: 'Buenos Aires',
        certificate_name: 'Test Participant',
        certificate_background_image_url: 'test-image.jpg',
        certificate_new_version: '1',
        certificate_kleer_cert: '0'
      }
    end

    context 'when successful' do
      it 'generates certificate data' do
        result = described_class.generate_certificate_pdf(event_type, certificate_params)

        expect(result).to be_success
        expect(result.data[:certificate]).to be_present
        expect(result.data[:participant]).to be_present
        expect(result.data[:event]).to be_present
        expect(result.data[:certificate_store]).to be_present
      end

      it 'correctly configures the event' do
        result = described_class.generate_certificate_pdf(event_type, certificate_params)

        event = result.data[:event]
        expect(event.trainer).to eq(trainer1)
        expect(event.trainer2).to eq(trainer2)
        expect(event.country).to eq(country)
        expect(event.city).to eq('Buenos Aires')
        expect(event.date).to eq(Date.new(2024, 1, 15))
        expect(event.finish_date).to eq(Date.new(2024, 1, 16))
        expect(event.mode).to eq('cl') # Non-online country
      end

      it 'correctly configures the participant' do
        result = described_class.generate_certificate_pdf(event_type, certificate_params)

        participant = result.data[:participant]
        expect(participant.fname).to eq('Test Participant')
        expect(participant.status).to eq('A') # Attended
      end

      it 'sets online mode for online country' do
        online_country = create(:country, iso_code: 'OL')
        params = certificate_params.merge(certificate_country: online_country.id.to_s)

        result = described_class.generate_certificate_pdf(event_type, params)

        event = result.data[:event]
        expect(event.mode).to eq('ol')
      end

      it 'handles Kleer certification' do
        params = certificate_params.merge(certificate_kleer_cert: '1')

        result = described_class.generate_certificate_pdf(event_type, params)

        event = result.data[:event]
        participant = result.data[:participant]
        expect(event.event_type.is_kleer_certification).to be true
        expect(participant.status).to eq('K') # Certified
      end

      it 'handles single trainer' do
        params = certificate_params.merge(certificate_trainer2: '0')

        result = described_class.generate_certificate_pdf(event_type, params)

        event = result.data[:event]
        expect(event.trainer).to eq(trainer1)
        expect(event.trainer2).to be_nil
      end

      it 'handles new version certificate' do
        params = certificate_params.merge(
          certificate_new_version: '1',
          certificate_background_image_url: 'new-image-LETTER.jpg'
        )

        result = described_class.generate_certificate_pdf(event_type, params)

        event = result.data[:event]
        expect(event.event_type.new_version).to be true
        expect(event.event_type.kleer_cert_seal_image).to eq('new-image-LETTER.jpg')
      end

      it 'handles old version certificate' do
        params = certificate_params.merge(
          certificate_new_version: '0',
          certificate_background_image_url: 'old-image-LETTER.jpg'
        )

        result = described_class.generate_certificate_pdf(event_type, params)

        event = result.data[:event]
        expect(event.event_type.new_version).to be false
        expect(event.event_type.kleer_cert_seal_image).to eq('old-image.jpg')
      end
    end

    context 'when AWS credentials are missing' do
      before do
        allow(ParticipantsHelper::Certificate).to receive(:new).and_raise(Aws::Errors::MissingCredentialsError)
      end

      it 'returns failure result with AWS error' do
        result = described_class.generate_certificate_pdf(event_type, certificate_params)

        expect(result).to be_failure
        expect(result.message).to eq('Missing AWS credentials - call support')
      end
    end

    context 'when trainer is not found' do
      let(:invalid_params) do
        certificate_params.merge(certificate_trainer1: '999999')
      end

      it 'returns failure result' do
        result = described_class.generate_certificate_pdf(event_type, invalid_params)

        expect(result).to be_failure
        expect(result.message).to include('Error generating certificate')
      end
    end

    context 'when date parsing fails' do
      let(:invalid_params) do
        certificate_params.merge(certificate_date: 'invalid-date')
      end

      it 'returns failure result' do
        result = described_class.generate_certificate_pdf(event_type, invalid_params)

        expect(result).to be_failure
        expect(result.message).to include('Error generating certificate')
      end
    end
  end

  describe 'Result class' do
    it 'has success? and failure? methods' do
      success_result = EventTypeCertificatePreviewService::Result.new(success: true, data: { test: 'data' })
      failure_result = EventTypeCertificatePreviewService::Result.new(success: false, message: 'Error')

      expect(success_result).to be_success
      expect(success_result).not_to be_failure
      expect(success_result.data[:test]).to eq('data')

      expect(failure_result).to be_failure
      expect(failure_result).not_to be_success
      expect(failure_result.message).to eq('Error')
    end
  end
end
