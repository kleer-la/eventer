class PopulateNewPricingForFutureEvents < ActiveRecord::Migration
  
  def up

  	Event.visible.each do |ev|
  		if !ev.list_price.nil? && ev.list_price > 0
  			
  			ev.eb_price = (ev.list_price.to_f * 0.95).ceil unless !ev.eb_price.nil?
  			ev.couples_eb_price = (ev.list_price.to_f * 0.90).ceil unless !ev.couples_eb_price.nil?

  			ev.business_price = (ev.list_price.to_f * 0.88).ceil unless !ev.business_price.nil?
  			ev.business_eb_price = (ev.list_price.to_f * 0.85).ceil unless !ev.business_eb_price.nil?

  			ev.enterprise_6plus_price = (ev.list_price.to_f * 0.83).ceil unless !ev.enterprise_6plus_price.nil?
  			ev.enterprise_11plus_price = (ev.list_price.to_f * 0.80).ceil unless !ev.enterprise_11plus_price.nil?

  			begin
	  			ev.save!
	  		rescue => err
				puts "No se pudo actualizar el evento #{ev.id}: #{err}"
			end
		end
	end
  end
 
  def down

  	Event.visible.each do |ev|
  		if !ev.list_price.nil? && ev.list_price > 0
  			ev.eb_price = nil
  			ev.couples_eb_price = nil

  			ev.business_price = nil
  			ev.business_eb_price = nil

  			ev.enterprise_6plus_price = nil
  			ev.enterprise_11plus_price = nil

  			begin
	  			ev.save!
	  		rescue => err
				puts "No se pudo revfertir el evento #{ev.id}: #{err}"
			end
  		end
  	end
  end
end
