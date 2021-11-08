class Api::V3::ParticipantsController < ApplicationController
  def interest
    event_id= params[:event_id].to_i
    event_type_id= params[:event_type_id].to_i
    if event_id == 0 and event_type_id > 0
      event_id = Event.public_courses.where("event_type_id=?", event_type_id)[0].id
    end

    _interest_event(event_id) if event_id > 0
  end

private

  def _interest_event(id)
    event = Event.find(id)
    result = event&.interested_participant(
      params[:firstname], params[:lastname], 
      params[:email], params[:country_iso],
      params[:notes]
    ) 
    if result.present?
      render json: {error: result}, status: 400
    else
      render json: {data: nil}, status: 200
    end
  end  
end
