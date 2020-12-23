# encoding: utf-8

require "spec_helper"
describe EventMailer do
    before :each do
        @participant = FactoryBot.build(:participant)
        @participant.email = "app_test@kleer.la"
        @participant.event.event_type.name = "Concurso de truco"
        ActionMailer::Base.deliveries.clear
    end
    
    it "welcome_new_webinar_participant", :pending => "Deprecated - should remove" do fail;end
    it "notify_webinar_start" , :pending => "Deprecated - should remove"  do fail;end
    it "alert_event_crm_push_finished" , :pending => "Deprecated - should remove" do fail;end

    context 'welcome_new_event_participant' do
        after :each do
            #default from
            expect(@email.from).to eq ["entrenamos@kleer.la"]
        end
        it "should queue and verify a simple email" do
            @email = EventMailer.welcome_new_event_participant(@participant).deliver
            expect(ActionMailer::Base.deliveries.count).to be 1
            expect(@email.to).to eq ["app_test@kleer.la"]
            expect(@email.subject).to eq "Kleer | Concurso de truco"
        end
        it "should send the certificate e-mail" do
            @participant.influence_zone = FactoryBot.create(:influence_zone)
            @participant.status = "A"

            @email = EventMailer.send_certificate(@participant, 'http://pepe.com/A4.pdf', 'http://pepe.com/LETTER.pdf').deliver

            expect(ActionMailer::Base.deliveries.count).to be 1
        end
    end

    context 'alert_event_monitor' do
        it 'dont send registration when the event dont have alert email address' do
            email= EventMailer.alert_event_monitor(@participant, '')
            expect(email.body).to eq ''
        end
        it 'send registration in event with alert email address' do
            @participant.event = FactoryBot.create(:event)
            @participant.event.monitor_email = "eventos@k.com"
            @participant.fname = 'Martin'
            @participant.lname = 'Salias'
            @participant.phone = "1234-5678"
            @participant.notes = "questions"
            edit_registration_link = "http://fighters.foo/events/1/participants/2/edit"
            email= EventMailer.alert_event_monitor(@participant, edit_registration_link)
            expect(email.subject).to include('Martin Salias')
            expect(email.body).to include('app_test@kleer.la')
            expect(email.body).to include('Martin Salias')
            expect(email.body).to include('1234-5678')
            expect(email.body).to include("questions")
            expect(email.from).to eq ["entrenamos@kleer.la"]
        end
    end


end

#   it "should send standard prices text info if custom prices text is empty" do
#     @participant.event.list_price = 200

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should include("(ARS) $ 200.00")
#   end

#   it "should send standard prices html info if custom prices html is empty" do
#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("(ARS) $ 200.00")
#   end

#   it "should not send early bird prices EB info is empty" do
#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should_not include("Si pagas antes del")
#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should_not include("Si pagas antes del")
#   end

#   it "should send early bird prices EB info is available" do
#     @participant.event.eb_end_date = Date.today
#     @participant.event.eb_price = 180

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should include("(ARS) $ 180.00")
#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("(ARS) $ 180.00")
#   end

#   it "should show 2 person price if present" do
#     @participant.event.couples_eb_price = 950

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should include("950.00 pagando de a 2 personas antes del")

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("950.00 pagando de a 2 personas antes del")
#   end

#   it "should show 5 person price if present" do
#     @participant.event.business_eb_price = 850

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should include("850.00 pagando de a 5 personas antes del")

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("850.00 pagando de a 5 personas antes del")
#   end

#   it "should not send list price or early bird prices if custom text is present" do
#     @participant.event.list_price = 200
#     @participant.event.eb_end_date = Date.today
#     @participant.event.eb_price = 180
#     @participant.event.couples_eb_price = 100
#     @participant.event.business_eb_price = 150

#     @participant.event.custom_prices_email_text = "texto customizado"

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should_not include("(ARS) $ 200.00")
#     text_message.should_not include("(ARS) $ 180.00")
#     text_message.should_not include("pagando de a 2 personas")
#     text_message.should_not include("pagando de a 5 personas")

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should_not include("(ARS) $ 200.00")
#     html_message.should_not include("(ARS) $ 180.00")
#     html_message.should_not include("Si pagas antes del")
#     html_message.should_not include("pagando de a 2 personas")
#     html_message.should_not include("pagando de a 5 personas")
#   end

#   it "should send the custom text if custom text is present" do
#     @participant.event.custom_prices_email_text = "texto customizado"

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     text_message = email.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
#     text_message.should include("texto customizado")
#     expect(text_message).not_to include("Promociones no acumulables")

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("texto customizado")
#     expect(html_message).not_to include("Promociones no acumulables")
#   end

#   it "should send the custom text in HTML format if custom text markdown is present" do
#     @participant.event.custom_prices_email_text = "**texto customizado**: 16"

#     email = EventMailer.welcome_new_event_participant(@participant).deliver

#     html_message = email.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
#     html_message.should include("<strong>texto customizado</strong>: 16")

#   end
#   context 'alert_event_crm_push_finished' do
#     it 'dont send notification when PushTransation dont have email address' do
#       email= EventMailer.alert_event_crm_push_finished(CrmPushTransaction.new)
#       expect(email.body).to eq ''
#     end

#     it 'send registration in event with alert email address' do
#       cpt= CrmPushTransaction.new
#       cpt.user= FactoryBot.build(:user)
#       email= EventMailer.alert_event_crm_push_finished(cpt)

#       expect(email.subject).to include('CRM finalizado')
#       expect(email.body).to include('finalizado')
#     end
#   end


# end
