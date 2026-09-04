# frozen_string_literal: true

require 'rails_helper'

# Loading a course that was given off the books, and issuing its certificate:
# event type, event, participant, PDF — in that order, because each one needs
# the previous. A certificate is only verifiable at kleer.la/certificado once
# the PDF sits in S3, and the PDF reads its text off all three records.
RSpec.describe 'MCP tools for courses and certificates', type: :request do
  let(:user) { create(:administrator) }
  let(:oauth_application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end
  let(:headers) do
    token = Doorkeeper::AccessToken.create!(application: oauth_application, resource_owner_id: user.id,
                                            scopes: 'mcp', expires_in: 2.hours, use_refresh_token: true)
    { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_AUTHORIZATION' => "Bearer #{token.plaintext_token}" }
  end

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  describe 'event types' do
    it 'lists them with what the certificate needs to name the course' do
      create(:event_type, name: 'Scrum Fundamentals', duration: 16)

      listing = call_tool('list_event_types', { query: 'Scrum' })

      expect(listing['returned']).to eq(1)
      expect(listing['event_types'].first)
        .to include('name' => 'Scrum Fundamentals', 'duration' => 16, 'lang' => 'es',
                    'trainers' => ['Juan Alberto'])
    end

    it 'creates one out of the public catalog, and says so' do
      create(:trainer, name: 'Alicia Coach')
      fields = { name: 'Facilitación in-company', description: 'Un taller', recipients: 'Equipos',
                 program: 'Un programa', elevator_pitch: 'Corto', duration: 8, trainers: ['Alicia Coach'] }

      preview = call_tool('create_event_type', fields)
      expect(preview['status']).to eq('preview')
      expect(preview['warnings'].join).to include('catalog')
      expect(EventType.find_by(name: 'Facilitación in-company')).to be_nil

      result = call_tool('create_event_type', fields.merge(confirm: true))
      expect(result['status']).to eq('saved')

      created = EventType.find(result['id'])
      expect(created.include_in_catalog).to be(false)
      expect(created.trainers.map(&:name)).to eq(['Alicia Coach'])
    end

    it 'refuses a trainer it does not know, and names the ones it does' do
      create(:trainer, name: 'Alicia Coach')

      result = call_tool('create_event_type', { name: 'Taller', description: 'd', recipients: 'r',
                                                program: 'p', elevator_pitch: 'e', trainers: ['Quien Sea'] })

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Quien Sea', 'Alicia Coach')
    end
  end

  describe 'events' do
    let(:event_type) { create(:event_type, name: 'Scrum Fundamentals') }
    # The test database keeps whatever earlier before(:all) blocks left behind,
    # so reuse Argentina if it is already there instead of adding a second one.
    let!(:country) { Country.find_by(name: 'Argentina') || create(:country) }
    let!(:trainer) { create(:trainer, name: 'Alicia Coach') }

    let(:fields) do
      { event_type_id: event_type.id, date: '2026-05-12', country: 'Argentina', trainer: 'Alicia Coach',
        city: 'Buenos Aires', place: 'Oficinas del cliente', address: 'Av. Corrientes 1234' }
    end

    it 'creates a past, private one by default: a backfill is not a course on sale' do
      result = call_tool('create_event', fields.merge(confirm: true))
      expect(result['status']).to eq('saved')

      event = Event.find(result['id'])
      expect(event.visibility_type).to eq('pr')
      expect(event.date.to_date).to eq(Date.new(2026, 5, 12))
      expect(event.event_type).to eq(event_type)
      expect(event.trainer).to eq(trainer)
      expect(event.country).to eq(country)
    end

    it 'takes a course given last year: nothing in the model asks for a future date' do
      result = call_tool('create_event', fields.merge(date: '2024-03-15', confirm: true))

      event = Event.find(result['id'])
      expect(event.date.to_date).to eq(Date.new(2024, 3, 15))
      # And being in the past, it is not one of the events the site shows.
      expect(Event.visible).not_to include(event)
    end

    it 'takes the country by ISO code too' do
      result = call_tool('create_event', fields.merge(country: 'AR', confirm: true))

      expect(Event.find(result['id']).country.iso_code).to eq('AR')
    end

    it 'passes the model validations through instead of half-saving' do
      result = call_tool('create_event', fields.merge(mode: 'ol', confirm: true))

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to match(/[Tt]ime zone/)
      expect(Event.where(place: 'Oficinas del cliente')).to be_empty
    end

    it 'lists events with their participant count' do
      event = create(:event, event_type: event_type, city: 'Rosario')
      create(:participant, event: event)

      listing = call_tool('list_events', { query: 'Scrum' })

      expect(listing['events'].first).to include('city' => 'Rosario', 'participants' => 1,
                                                 'event_type' => 'Scrum Fundamentals')
    end
  end

  describe 'participants' do
    let(:event) { create(:event) }

    it 'creates one and reports the verification code the certificate will carry' do
      result = call_tool('create_participant', { event_id: event.id, fname: 'Gonzalo', lname: 'Pérez',
                                                 email: 'gonzalo@example.com', status: 'A', confirm: true })

      expect(result['status']).to eq('saved')
      participant = Participant.find(result['id'])
      expect(participant.status).to eq('A')
      expect(result['verification_code']).to eq(participant.verification_code)
    end

    it 'refuses to list the whole database: a search needs a term or an event' do
      create(:participant, fname: 'Gonzalo')

      result = call_tool('search_participants')

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('query')
    end

    it 'finds by name, e-mail or verification code, and says whether the certificate can be issued' do
      participant = create(:participant, fname: 'Gonzalo', lname: 'Pérez', status: 'A', event: event,
                                         verification_code: 'ABC123')

      by_name = call_tool('search_participants', { query: 'gonzalo' })
      expect(by_name['participants'].first).to include('id' => participant.id, 'status' => 'A',
                                                       'verification_code' => 'ABC123',
                                                       'certificate_ready' => true)

      expect(call_tool('search_participants', { query: 'ABC123' })['returned']).to eq(1)
      expect(call_tool('search_participants', { query: 'malaimo@gmail.com' })['returned']).to eq(1)
    end

    it 'says why a certificate cannot be issued yet' do
      create(:participant, fname: 'Gonzalo', status: 'N', event: event)

      found = call_tool('search_participants', { query: 'gonzalo' })['participants'].first

      expect(found['certificate_ready']).to be(false)
      expect(found['certificate_blocked_by'].join).to include('Presente')
    end
  end

  describe 'issuing the certificate' do
    # A course given last year, which is what these tools are for.
    let(:event) { create(:event, date: Date.new(2024, 3, 15)) }
    let(:participant) { create(:participant, fname: 'Gonzalo', lname: 'Pérez', status: 'A', event: event) }

    before do
      allow(FileStoreService).to receive(:create_s3).and_return(FileStoreService.create_null)
      allow(ParticipantsHelper).to receive(:upload_certificate) { |path| "https://s3/#{File.basename(path)}" }
    end

    it 'previews without generating anything' do
      result = call_tool('issue_certificate', { participant_id: participant.id })

      expect(result['status']).to eq('preview')
      expect(result['participant']).to include('name' => 'Gonzalo Pérez')
      expect(result['participant']['date'].to_s).to start_with('2024-03-15')
      expect(ParticipantsHelper).not_to have_received(:upload_certificate)
    end

    it 'generates both page sizes and hands back the code to check at kleer.la/certificado' do
      result = call_tool('issue_certificate', { participant_id: participant.id, confirm: true })

      expect(result['status']).to eq('issued')
      expect(result['urls'].keys).to contain_exactly('A4', 'LETTER')
      expect(result['verification_code']).to eq(participant.verification_code)
      expect(result['verify_at']).to include(participant.verification_code)
      expect(result['notified']).to be(false)
    end

    it 'only mails the participant when asked' do
      expect do
        call_tool('issue_certificate', { participant_id: participant.id, confirm: true })
      end.not_to(change { ActionMailer::Base.deliveries.count })

      expect do
        call_tool('issue_certificate', { participant_id: participant.id, notify: true, confirm: true })
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'refuses a participant who did not attend' do
      pending_participant = create(:participant, status: 'N', event: event)

      result = call_tool('issue_certificate', { participant_id: pending_participant.id, confirm: true })

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('Presente')
    end

    it 'refuses when the trainer has no signature: the PDF would come out unsigned' do
      event.trainer.update_column(:signature_image, nil)

      result = call_tool('issue_certificate', { participant_id: participant.id, confirm: true })

      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('signature')
    end
  end

  describe 'permissions' do
    let(:user) { create(:comercial) }

    it 'lets a read-only role search but not load or issue' do
      participant = create(:participant, fname: 'Gonzalo', status: 'A')

      expect(call_tool('search_participants', { query: 'gonzalo' })['returned']).to eq(1)
      expect(call_tool('create_participant', { event_id: participant.event_id, fname: 'A', lname: 'B',
                                               email: 'a@b.com', confirm: true }).to_s).to include('Unauthorized')
      expect(call_tool('issue_certificate', { participant_id: participant.id,
                                              confirm: true }).to_s).to include('Unauthorized')
    end
  end
end
