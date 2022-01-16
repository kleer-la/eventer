# frozen_string_literal: true

require 'rails_helper'

describe EventMailer do
  before :each do
    @participant = FactoryBot.build(:participant)
    @participant.email = 'app_test@kleer.la'
    @participant.event.event_type.name = 'Concurso de truco'
    ActionMailer::Base.deliveries.clear
    EventMailer.xero(XeroClientService.create_null())
  end

  context 'welcome_new_event_participant' do
    eb_text = 'Pronto pago:'
    pair_text = 'En parejas:'
    group_text = 'Grupos (5 o más):'
    ar_text = 'pagos desde Argentina'

    it 'should queue and verify a simple email' do
      @email = EventMailer.welcome_new_event_participant(@participant).deliver_now
      # File.open("x.html", 'w') { |file| file.write(@email) }
      expect(ActionMailer::Base.deliveries.count).to be 1
      expect(@email.to).to eq ['app_test@kleer.la']
      expect(@email.subject).to eq 'Kleer | Concurso de truco'
      expect(@email.text_part.body.to_s).to include 'Concurso de truco'
      expect(@email.html_part.body.to_s).to include 'Concurso de truco'
      expect(@email.from).to eq ['entrenamos@kleer.la']
    end
    it 'should send standard prices text info if custom prices text is empty' do
      @participant.event.list_price = 200

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).to include 'ARS 200'
      expect(email.html_part.body.to_s).to include 'ARS 200'
    end
    it 'should not send early bird prices if EB info is empty' do
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include eb_text
      expect(email.html_part.body.to_s).not_to include eb_text
    end

    it 'should send early bird prices if EB info is available' do
      @participant.event.eb_end_date = Date.today
      @participant.event.eb_price = 180

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).to include eb_text
      expect(email.html_part.body.to_s).to include eb_text
      expect(email.text_part.body.to_s).to include 'ARS 180'
      expect(email.html_part.body.to_s).to include 'ARS 180'
    end

    it 'should not show 2 person price if NOT present' do
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include pair_text
      expect(email.html_part.body.to_s).not_to include pair_text
    end
    it 'should show 2 person price if present' do
      @participant.event.couples_eb_price = 950

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).to include pair_text
      expect(email.html_part.body.to_s).to include pair_text
      expect(email.text_part.body.to_s).to include 'ARS 950'
      expect(email.html_part.body.to_s).to include 'ARS 950'
    end

    it 'should not show group price if NOT present' do
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include group_text
      expect(email.html_part.body.to_s).not_to include group_text
    end
    it 'should show group price if present' do
      @participant.event.business_eb_price = 850

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).to include group_text
      expect(email.html_part.body.to_s).to include group_text
      expect(email.text_part.body.to_s).to include 'ARS 850 cada uno abonando antes del'
      expect(email.html_part.body.to_s).to include 'ARS 850 cada uno abonando antes del'
    end

    it 'should replace all prices if custom text is present' do
      @participant.event.list_price = 200
      @participant.event.eb_end_date = Date.today
      @participant.event.eb_price = 180
      @participant.event.couples_eb_price = 100
      @participant.event.business_eb_price = 150

      @participant.event.custom_prices_email_text = 'texto customizado'

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include eb_text
      expect(email.html_part.body.to_s).not_to include eb_text
      expect(email.text_part.body.to_s).not_to include pair_text
      expect(email.html_part.body.to_s).not_to include pair_text
      expect(email.text_part.body.to_s).not_to include group_text
      expect(email.html_part.body.to_s).not_to include group_text
      expect(email.text_part.body.to_s).not_to include 'ARS 200'
      expect(email.html_part.body.to_s).not_to include 'ARS 200'
      expect(email.text_part.body.to_s).not_to include 'ARS 180'
      expect(email.html_part.body.to_s).not_to include 'ARS 180'
      expect(email.text_part.body.to_s).not_to include 'ARS 100'
      expect(email.html_part.body.to_s).not_to include 'ARS 100'
      expect(email.text_part.body.to_s).not_to include 'ARS 150'
      expect(email.html_part.body.to_s).not_to include 'ARS 150'

      expect(email.text_part.body.to_s).to include 'texto customizado'
      expect(email.html_part.body.to_s).to include 'texto customizado'
    end

    it 'should send the custom text in HTML format if custom text markdown is present' do
      @participant.event.custom_prices_email_text = '**texto customizado**: 16'

      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.html_part.body.to_s).to include '<strong>texto customizado</strong>: 16'
    end
    it 'should NOT show extra info if participant NOT from AR' do
      @participant.influence_zone.country.iso_code = 'CL'
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include ar_text
      expect(email.html_part.body.to_s).not_to include ar_text
    end
    it 'should show extra info if participant from AR' do
      @participant.influence_zone.country.iso_code = 'AR'
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now

      expect(email.text_part.body.to_s).not_to include ar_text
      expect(email.html_part.body.to_s).not_to include ar_text
    end
  end

  it 'should send the certificate e-mail' do
    @participant.influence_zone = FactoryBot.create(:influence_zone)
    @participant.status = 'A'

    @email = EventMailer.send_certificate(@participant, 'http://pepe.com/A4.pdf', 'http://pepe.com/LETTER.pdf').deliver_now

    expect(ActionMailer::Base.deliveries.count).to be 1
    expect(@email.from).to eq ['entrenamos@kleer.la']
  end

  context 'alert_event_monitor' do
    it 'send registration to AlertMail when the event dont have alert email address' do
      @email = EventMailer.alert_event_monitor(@participant, '')
      expect(@email.to).to eq ['entrenamos@kleer.la']
    end
    it 'send registration in event with alert email address' do
      @participant.event = FactoryBot.create(:event)
      @participant.event.monitor_email = 'eventos@k.com'
      @participant.fname = 'Martin'
      @participant.lname = 'Salias'
      @participant.phone = '1234-5678'
      @participant.notes = 'questions'
      @participant.id_number = '20-12358132-1'
      @participant.address = 'Tatooine'

      edit_registration_link = 'http://fighters.foo/events/1/participants/2/edit'
      @email = EventMailer.alert_event_monitor(@participant, edit_registration_link)
      expect(@email.subject).to include('Martin Salias')
      expect(@email.body).to include('app_test@kleer.la')
      expect(@email.body).to include('Martin Salias')
      expect(@email.body).to include('1234-5678')
      expect(@email.body).to include('questions')
      expect(@email.body).to include('20-12358132-1')
      expect(@email.body).to include('Tatooine')
      expect(@email.from).to eq ['entrenamos@kleer.la']
    end
    it 'send qty & price' do
      @participant.event = FactoryBot.create(:event, list_price: 123.4, eb_end_date: nil)
      @participant.quantity = 2
      @email = EventMailer.alert_event_monitor(@participant, '')
      expect(@email.body).to include('123.4')
      expect(@email.body).to include('246.8')
      expect(@email.body).to include('2 personas')
    end
  end
end
