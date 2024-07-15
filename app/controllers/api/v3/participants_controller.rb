# frozen_string_literal: true

# let response = fetch('/api/v3/participants/interest', {
#   method: 'POST',
#   headers: {
#     'Content-Type': 'application/json;charset=utf-8'
#   },
#   data: { "event_type_id": "1",
#          "event_id": "0",
#           "firstname": 'New',
#           "lastname": 'Participant',
#           "country_iso": 'AR',
#           "email": 'new@gmail.com',
#           "notes": 'New comment'
#         }
# });

module Api
  module V3
    class ParticipantsController < Api::V3::BaseController
      # TODO: remove - not used
      def interest
        params.permit!
        event_id = params[:event_id].to_i
        event_type_id = params[:event_type_id].to_i
        # p params.inspect
        # params.each do |single|
        #   p single
        # end

        if event_id.zero? && event_type_id.positive?
          event_id = Event.public_courses.where('event_type_id=?', event_type_id)[0]&.id
          # p '1---', event_id
        end

        result = _interest_event(event_id) if event_id.to_i.positive?
        # p '3---', result
        if result.present?
          render json: { error: result }, status: 400
        else
          render json: { data: nil }, status: 200
        end
      end

      private

      def _interest_event(id)
        event = Event.find(id)
        # p '2---', event
        event&.interested_participant(
          params[:firstname], params[:lastname],
          params[:email], params[:country_iso],
          params[:notes]
        )
      end

      def participants_params
        params.require(:participants).permit(:event_type_id, :event_id, :firstname, :lastname, :email, :country_iso,
                                             :notes)
      end
    end
  end
end
