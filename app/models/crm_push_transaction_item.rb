require 'curb'
require 'json'
require 'open-uri'

class CrmPushTransactionItem < ActiveRecord::Base

  belongs_to :crm_push_transaction
  belongs_to :participant

  def push!
  	self.result = "Errored/Halted"

  	self.log = "001 push iniciado para #{self.participant.email}\n"

  	crm_ids = get_crm_ids(self.participant.email)

  	if crm_ids.size == 0
	    self.log += "002 persona inexistente en CRM\n"
	    new_id = create_crm_person(self.participant)
	    self.result = "Created"

	    add_crm_tag new_id, self.participant.influence_zone_tag

	    if self.participant.is_present?
			apply_event_tags new_id, crm_push_transaction.event
		end

    else
    	if self.participant.is_present?
	    	crm_ids.each do |crm_id|
	    		self.log += "004 actualizando persona con id:#{crm_id}\n"
	    		apply_event_tags crm_id, crm_push_transaction.event
	    	end
	    	self.result = "Updated"
    	end
    end

  	self.save
  end

  private

  def apply_event_tags(crm_id, event)
  	add_crm_tag crm_id, event.event_type.tag_name
  	add_crm_tag crm_id, event.trainer.tag_name
  end

  def create_crm_person(participant)
  	c = create_crm_curl("https://kleer.capsulecrm.com/api/person")
	c.headers['Content-Type'] = 'application/xml'

	new_crm_person_xml = "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>" +
				 "<person>" +
					"<firstName>#{participant.fname}</firstName>" +
					"<lastName>#{participant.lname}</lastName>" +
					"<contacts>" +
						"<email>" +
							"<emailAddress>#{participant.email}</emailAddress>" +
						"</email>" +
					"</contacts>" +
				 "</person>"

	c.http_post( new_crm_person_xml )

	redirect_url = c.header_str.match(/Location: (.*)/).to_s
	from_index = redirect_url.rindex("/")+1
	to_index = redirect_url.length-1
	new_id = redirect_url[from_index..to_index].strip

  	self.log += "003 persona creada con ID #{new_id} en CRM\n"

	new_id

  end

  def add_crm_tag(id_crm, tag)
  	  if !tag.nil? && tag != ""
		  encoded_tag = URI::encode(tag)
		  c = create_crm_curl("https://kleer.capsulecrm.com/api/party/#{id_crm}/tag/#{encoded_tag}")
		  c.http_post
		  self.log += "004 tag #{tag} aplicada\n"
	  end
  end

  def get_crm_ids(email)
	  crm_ids = Array.new

	  encoded_email = URI::encode(email)
	  c = create_crm_curl("https://kleer.capsulecrm.com/api/party?email=#{encoded_email}")
	  c.headers["Accept"] = "application/json"
	  c.http_get
	  response = JSON.parse( c.body_str )

	  if response["parties"]["@size"].to_i > 0
	    if response["parties"]["person"].class == Hash
	      crm_ids << response["parties"]["person"]["id"]
	    elsif response["parties"]["person"].class == Array
	      response["parties"]["person"].each do |person|
	        crm_ids << person["id"]
	      end
	    end
	  end

	  crm_ids

  end

  def create_crm_curl(url)
	  c = Curl::Easy.new(url)

	  c.http_auth_types = :basic
	  c.username = ENV["KEVENTER_CRM_TOKEN"]
	  c.password = ENV["KEVENTER_CRM_PASSWORD"]

	  c
  end
end
