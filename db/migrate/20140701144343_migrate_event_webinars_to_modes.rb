# frozen_string_literal: true

class MigrateEventWebinarsToModes < ActiveRecord::Migration[4.2]
  def up
    Event.where("is_webinar = 't'").each do |e|
      if e.list_price > 0.0
        e.mode = 'ol'
        e.visibility_type = 'co'
      else
        e.mode = 'cl'
      end
      e.save! if e.valid?
    end
  end

  def down
    Event.where("is_webinar = 't'").each do |e|
      e.mode = nil
      e.visibility_type = 'co' if e.list_price > 0.0
      e.save! if e.valid?
    end
  end
end
