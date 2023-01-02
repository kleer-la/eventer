# frozen_string_literal: true

class AddDurationAndTimeToEvent < ActiveRecord::Migration[4.2]
  class Event < ApplicationRecord
    belongs_to :country
    scope :visible, -> { where(cancelled: false).where('date >= ?', DateTime.now) }
  end

  def up
    change_table :events do |t|
      t.integer :duration
      t.time :start_time
      t.time :end_time
    end

    Event.reset_column_information
    Event.visible.each do |e|
      if e.country.iso_code == 'CO'
        e.update_attributes!({ start_time: '8:00', end_time: '17:00' })
      else
        e.update_attributes!({ start_time: '9:00', end_time: '18:00' })
      end
    end
  end

  def down
    remove_column :events, :duration
    remove_column :events, :start_time
    remove_column :events, :end_time
  end
end
