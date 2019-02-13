class MailChimpService
  def MailChimpService.automation_workflow_list
    "46a03b3eb3"
  end
  def subscribe_email_to_workflow workflow_call, list_id, participant
    mailchimp = MailchimpConnector.new
    email = participant.email
    memberBody = mailchimp.get_member email, list_id
    memberStatus = JSON.parse(memberBody)['status']
    if memberStatus==404
      puts "El cliente no esta previamente registrado. Procederemos a registrarlo."
      mailchimp.subscribe_email list_id, email, workflow_call, participant
    elsif memberStatus=="unsubscribed"
      puts "El cliente se ha dado de baja (unsubscribe). No podemos iniciar el workflow."
    elsif memberStatus=="subscribed"
      puts "Enviando mail..."
      mailchimp.start_workflow workflow_call, email
    else
      puts memberBody
    end
  end
  def subscribe_email_to_workflow_using_automation_workflow_list workflow_call, participant
    subscribe_email_to_workflow workflow_call, MailChimpService.automation_workflow_list, participant
  end
end