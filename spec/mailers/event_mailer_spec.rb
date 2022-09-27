# frozen_string_literal: true

require 'rails_helper'

describe EventMailer do
  before :each do
    @participant = FactoryBot.create(:participant)
    @participant.email = 'app_test@kleer.la'
    @participant.event.event_type.name = 'Concurso de truco'
    ActionMailer::Base.deliveries.clear
  end

  context 'welcome_new_event_participant' do
    eb_text = 'Pronto pago:'
    pair_text = 'En parejas:'
    group_text = 'Grupos (5 o más):'
    ar_text = 'pagos desde Argentina'

    before :each do
      EventMailer.xero_service(XeroClientService.create_null)
    end

    context 'English' do
      before :each do
        @participant.event.event_type.lang = :en
      end
      it 'English html' do
        @email = EventMailer.welcome_new_event_participant(@participant).deliver_now
        html = @email.html_part.body.to_s
        expect(html).to include 'Hello'
        expect(html).to include 'Pay now'
        expect(html).to include 'Time:'
        expect(html).not_to include "t('"
        expect(html).not_to include 'translation'
      end
      it 'English test' do
        @email = EventMailer.welcome_new_event_participant(@participant).deliver_now
        text = @email.text_part.body.to_s
        expect(text).to include 'Hello'
        expect(text).to include 'Time:'
        expect(text).not_to include "t('"
        expect(text).not_to include 'translation'
      end
    end
  
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

    it 'When sold out canT pay' do
      @participant.event.is_sold_out = true
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now
      expect(email.html_part.body.to_s).to include 'lista de espera'
      expect(email.html_part.body.to_s).not_to include 'Pagar'
    end
    it 'When NOT sold out can pay' do
      @participant.event.is_sold_out = false
      email = EventMailer.welcome_new_event_participant(@participant).deliver_now
      expect(email.html_part.body.to_s).not_to include 'lista de espera'
      expect(email.html_part.body.to_s).to include 'Pagar'
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
    context 'Update participant' do
      it 'set invoice number' do
        EventMailer.welcome_new_event_participant(@participant).deliver_now
        expect(@participant.xero_invoice_number).to eq 'INV-0100' # from NullInvoice
      end
    end
    context 'Create Invoice' do
      before :each do
        @participant.event.date = DateTime.new(2022, 1, 20)
        @participant.event.eb_end_date = DateTime.new(2022, 1, 10)
      end
      it 'normal due date' do
        due_date = EventMailer.due_date(@participant.event, DateTime.new(2022, 1, 1))
        expect(due_date.to_date.to_s).to eq '2022-01-08'
      end
      it 'normal due date > eb' do
        due_date = EventMailer.due_date(@participant.event, DateTime.new(2022, 1, 4))
        expect(due_date.to_date.to_s).to eq '2022-01-10'
      end
      it 'normal due date > curse date' do
        due_date = EventMailer.due_date(@participant.event, DateTime.new(2022, 1, 14))
        expect(due_date.to_date.to_s).to eq '2022-01-19'
      end
      it 'no eb' do
        @participant.event.eb_end_date = nil
        due_date = EventMailer.due_date(@participant.event, DateTime.new(2022, 1, 4))
        expect(due_date.to_date.to_s).to eq '2022-01-11'
      end
      it 'today > eb' do
        due_date = EventMailer.due_date(@participant.event, DateTime.new(2022, 1, 11))
        expect(due_date.to_date.to_s).to eq '2022-01-18'
      end
      it 'Fail w/ Standard exceptions ' do
        EventMailer.xero_service(XeroClientService.create_null(
          invoice_exception: StandardError.new('Invoice error')
        ))
        expect {
          email = EventMailer.welcome_new_event_participant(@participant).deliver_now
        }.to change {Log.count}.by 1
      end
    end
    context 'Create Invoice' do
      it 'when event is sold out registration doesnt create an invoice' do
        @participant.event.is_sold_out = true
        @participant.event.save!
        email = EventMailer.welcome_new_event_participant(@participant).deliver_now
        expect(@participant.xero_invoice_number).to be_nil
      end
      it 'Fail w/ Standard exceptions ' do
        EventMailer.xero_service(XeroClientService.create_null(
          email_exception: StandardError.new('Email Invoice error')
        ))
        expect {
          email = EventMailer.welcome_new_event_participant(@participant).deliver_now
        }.to change {Log.count}.by 1
      end
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

describe ParticipantInvoiceHelper do
  before :each do
    @participant = FactoryBot.create(:participant)
  end
  it 'item_description one seat es' do
    pih = ParticipantInvoiceHelper.new(@participant, :es)
    expect(pih.item_description).to include 'por una vacante'
  end
  it 'item_description three seats es' do
    @participant.quantity =3
    pih = ParticipantInvoiceHelper.new(@participant, :es)
    expect(pih.item_description).to include 'por 3 vacantes'
  end
  it 'item_description one seat en' do
    pih = ParticipantInvoiceHelper.new(@participant, :en)
    expect(pih.item_description).to include 'one seat for'
  end
  it 'item_description three seats es' do
    @participant.quantity = 3
    pih = ParticipantInvoiceHelper.new(@participant, :en)
    expect(pih.item_description).to include '#3 seats'
  end
  
end