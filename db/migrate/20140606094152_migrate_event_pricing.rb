class MigrateEventPricing < ActiveRecord::Migration
  def up

  	Event.all.each do |ev|
  		if !ev.list_price.nil? && ev.list_price > 0
  			if ev.list_price_plus_tax
  				begin
  					ev.list_price = (ev.list_price*1.21)
					ev.save!
				rescue => err
					puts "No se pudo actualizar el evento #{ev.id}: #{err}"
				end
  			end

	    	if !ev.list_price_2_pax_discount.nil? && ev.list_price_2_pax_discount > 0
	    		couples_eb_price = nil
				if ev.list_price_2_pax_discount < 1
					couples_eb_price = (ev.list_price * (1-ev.list_price_2_pax_discount))
				else
					couples_eb_price = (ev.list_price * (100-ev.list_price_2_pax_discount) / 100)
				end
				begin
					ev.couples_eb_price = couples_eb_price
					ev.save!
				rescue => err
					puts "No se pudo actualizar el evento #{ev.id}: #{err}"
				end
			end
		end
	end
  end

  def down
  	Event.all.each do |ev|
		ev.update_attributes(:couples_eb_price => nil)
		if ev.list_price_plus_tax
			ev.update_attributes(:list_price => ev.list_price/1.21)
		end
  	end
  end
end
