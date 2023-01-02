# frozen_string_literal: true

class PopulateNewPricingForFutureEvents < ActiveRecord::Migration[4.2]
  def up
    Event.visible.each do |ev|
      next unless !ev.list_price.nil? && ev.list_price.positive?

      ev.eb_price = (ev.list_price.to_f * 0.95).ceil if ev.eb_price.nil?
      ev.couples_eb_price = (ev.list_price.to_f * 0.90).ceil if ev.couples_eb_price.nil?

      ev.business_price = (ev.list_price.to_f * 0.88).ceil if ev.business_price.nil?
      ev.business_eb_price = (ev.list_price.to_f * 0.85).ceil if ev.business_eb_price.nil?

      ev.enterprise_6plus_price = (ev.list_price.to_f * 0.83).ceil if ev.enterprise_6plus_price.nil?
      ev.enterprise_11plus_price = (ev.list_price.to_f * 0.80).ceil if ev.enterprise_11plus_price.nil?

      begin
        ev.save!
      rescue StandardError => e
        puts "No se pudo actualizar el evento #{ev.id}: #{e}"
      end
    end
  end

  def down
    Event.visible.each do |ev|
      next unless !ev.list_price.nil? && ev.list_price.positive?

      ev.eb_price = nil
      ev.couples_eb_price = nil

      ev.business_price = nil
      ev.business_eb_price = nil

      ev.enterprise_6plus_price = nil
      ev.enterprise_11plus_price = nil

      begin
        ev.save!
      rescue StandardError => e
        puts "No se pudo revfertir el evento #{ev.id}: #{e}"
      end
    end
  end
end
