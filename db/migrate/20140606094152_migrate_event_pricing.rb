# frozen_string_literal: true

class MigrateEventPricing < ActiveRecord::Migration[4.2]
  def up
    Event.all.each do |ev|
      next unless !ev.list_price.nil? && ev.list_price.positive?

      if ev.list_price_plus_tax
        begin
          ev.list_price = (ev.list_price * 1.21)
          ev.save!
        rescue StandardError => e
          puts "No se pudo actualizar el evento #{ev.id}: #{e}"
        end
      end

      next unless !ev.list_price_2_pax_discount.nil? && ev.list_price_2_pax_discount.positive?

      couples_eb_price = nil
      couples_eb_price = if ev.list_price_2_pax_discount < 1
                           (ev.list_price * (1 - ev.list_price_2_pax_discount))
                         else
                           (ev.list_price * (100 - ev.list_price_2_pax_discount) / 100)
                         end
      begin
        ev.couples_eb_price = couples_eb_price
        ev.save!
      rescue StandardError => e
        puts "No se pudo actualizar el evento #{ev.id}: #{e}"
      end
    end
  end

  def down
    Event.all.each do |ev|
      ev.update_attributes(couples_eb_price: nil)
      ev.update_attributes(list_price: ev.list_price / 1.21) if ev.list_price_plus_tax
    end
  end
end
