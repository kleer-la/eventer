# frozen_string_literal: true

class AjaxController < ApplicationController
  def events_update_trainer_select
    unless params[:id].blank?
      @trainers_for_event_type = EventType.find(params[:id]).trainers.sort do |p1, p2|
        p1.name <=> p2.name
      end
    end
    render '/events/_trainers_select', layout: false
  end

  def events_update_trainer2_select
    unless params[:id].blank?
      @trainers2_for_event_type = EventType.find(params[:id]).trainers.sort do |p1, p2|
        p1.name <=> p2.name
      end
    end
    @trainers2_for_event_type.unshift Trainer.new(name: 'No hay')
    render '/events/_trainers2_select', layout: false
  end

  def events_update_trainer3_select
    unless params[:id].blank?
      @trainers_for_event_type = EventType.find(params[:id]).trainers.sort do |p1, p2|
        p1.name <=> p2.name
      end
    end
    @trainers_for_event_type.unshift Trainer.new(name: 'No hay')
    render '/events/_trainers3_select', layout: false
  end

  def load_cancellation_policy
    @cancellation_policy = EventType.find(params[:id]).cancellation_policy
    render plain: @cancellation_policy.html_safe, layout: false
  end
end
