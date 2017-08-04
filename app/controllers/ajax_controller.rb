class AjaxController < ApplicationController
  def events_update_trainer_select
    @trainers_for_event_type = EventType.find(params[:id]).trainers.sort{|p1,p2| p1.name <=> p2.name} unless params[:id].blank?
    render "/events/_trainers_select", :layout => false
  end

  def events_update_trainer2_select
    @trainers2_for_event_type = EventType.find(params[:id]).trainers.sort{|p1,p2| p1.name <=> p2.name} unless params[:id].blank?
    @trainers2_for_event_type.unshift Trainer.new(name: "No hay")
    render "/events/_trainers2_select", :layout => false
  end

  def events_update_trainer3_select
    @trainers_for_event_type = EventType.find(params[:id]).trainers.sort{|p1,p2| p1.name <=> p2.name} unless params[:id].blank?
    @trainers_for_event_type.unshift Trainer.new(name: "No hay")
    render "/events/_trainers3_select", :layout => false
  end

  def load_cancellation_policy
    @cancellation_policy = EventType.find(params[:id]).cancellation_policy
    render text: @cancellation_policy, :layout => false
  end

end
