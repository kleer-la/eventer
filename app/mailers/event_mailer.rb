class EventMailer < ActionMailer::Base
  default from: "entrenamos@kleer.la"
  
  def welcome_new_webinar_participant(participant)
    @participant = participant
    mail(to: @participant.email, subject: "Kleer | Te has registrado al #{@participant.event.event_type.name}" )
  end
  
  def notify_webinar_start(participant, webinar_link)
    @participant = participant
    @webinar_link = webinar_link
    mail(to: @participant.email, subject: "Kleer | Estamos iniciando! Sumate al webinar #{@participant.event.event_type.name}" )
  end
  
end