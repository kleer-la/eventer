class MailchimpConnector
  def start_workflow workflow_call, email
    response = HTTParty.post("https://us1.api.mailchimp.com/3.0#{workflow_call}",
          :body => {:email_address => email}.to_json,
          :headers => { 'Content-Type' => 'application/json' },
          :basic_auth => {:username => "anystring", :password => "#{Eventer::Application.config.mailchimp_token}"})

    if response.body.nil?
      puts "Hurray! Ojo el envio de mail puede demorar unos minutos."
    else
      puts "Error: #{JSON.parse(response.body)['detail']}"
    end
  end

  def subscribe_email list_id, email, workflow_call, participant
    email_subscribe_call = "/lists/#{list_id}/members"

    puts "Ingresa el nombre del cliente:"
    email_firstname = participant.fname
    puts "Ingresa el apellido del cliente:"
    email_lastname = participant.lname

    response = HTTParty.post("https://us1.api.mailchimp.com/3.0#{email_subscribe_call}",
            :body => {:email_address => email, :status=>"subscribed", :merge_fields=>{"FNAME"=>email_firstname,"LNAME"=>email_lastname}}.to_json,
            :headers => { 'Content-Type' => 'application/json' },
            :basic_auth => {:username => "anystring", :password => "#{Eventer::Application.config.mailchimp_token}"})

    if JSON.parse(response.body)['status']=="subscribed"
      puts "Success: #{email} ha sido registrado."
      start_workflow workflow_call, email
    else
      puts "Warning: #{JSON.parse(response.body)['title']}"
    end

  end
  def get_member email, list_id
    email_md5 = Digest::MD5.hexdigest email.downcase
    email_validation_call = "/lists/#{list_id}/members/#{email_md5}"
    response = HTTParty.get("https://us1.api.mailchimp.com/3.0#{email_validation_call}",
                            :headers => { 'Content-Type' => 'application/json'},
                            :basic_auth => {:username => "anystring", :password => "#{Eventer::Application.config.mailchimp_token}"})
    response.body
  end
end
