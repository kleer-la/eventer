class Api::V3::ParticipantsController < ApplicationController
  def interest
    event_id= params[:event_id].to_i
    if event_id > 0
      _interest_event(event_id)
      return
    end
  end

private

  def _interest_event(id)
    event = Event.find(id)
    result = event.interested_participant(
      params[:firstname], params[:lastname], 
      params[:email], params[:country_iso]
    ) 
    if result.present?
      render json: {error: result}, status: 400
    else
      render json: {data: nil}, status: 200
    end
  end  
end
