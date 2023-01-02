# frozen_string_literal: true

class FillFinishDateForEvent < ActiveRecord::Migration[4.2]
  def up
    Event.all.each do |ev|
      next unless !ev.duration.nil? && ev.duration.positive?

      ev.finish_date = (ev.date + (ev.duration - 1))
      begin
        ev.save!
      rescue StandardError => e
        puts "No se pudo actualizar el evento #{ev.id}: #{e}"
      end
    end
  end

  def down
    Event.all.each do |ev|
      ev.finish_date = nil
      begin
        ev.save!
      rescue StandardError => e
        puts "No se pudo actualizar el evento #{ev.id}: #{e}"
      end
    end
  end
end
