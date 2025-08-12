# frozen_string_literal: true

class ApiController < ApplicationController

  def participants_synch
    api_token_provided = params[:api_token]
    api_password_provided = params[:api_password]
    keventer_api_token = ENV['KEVENTER_API_TOKEN']
    keventer_api_password = ENV['KEVENTER_API_PASSWORD']

    @authorized_call = (api_token_provided == keventer_api_token) && (api_password_provided == keventer_api_password)
    @event = nil
    @participant = nil

    if @authorized_call

      course_codename = params[:course_codename]
      cohort_codename = params[:cohort_codename]
      participant_email = params[:participant_email]
      participant_fname = params[:participant_fname]
      participant_lname = params[:participant_lname]
      utm_source = params[:utm_source]
      utm_campaign = params[:utm_campaign]
      status = params[:status]
      notes = params[:notes]
      po_number = params[:po_number]

      @event = Event.where('online_course_codename = ? AND online_cohort_codename = ?', course_codename,
                           cohort_codename).first
      unless @event.nil?


        @participant = @event.participants.where('email = ?', participant_email).last

        if @participant.nil?
          iz = InfluenceZone.where('zone_name = ? AND tag_name = ?', 'Capital Federal',
                                   'ZI-AMS-AR-BUE (Buenos Aires)').first
          @participant = @event.participants.create(email: participant_email, fname: participant_fname,
                                                    lname: participant_lname, influence_zone: iz, phone: 'N/A', notes:)
        else
          @participant.notes = "#{notes}\n#{@participant.notes}"
        end

        case status
        when 'KONLINE_NEW'
          @participant.status = Participant::STATUS[:new]
        when 'KONLINE_PURCHASED'
          @participant.status = Participant::STATUS[:confirmed]
        end

        @participant.konline_po_number = po_number
        @participant.save!
      end
    end

    render layout: false
  end
end
