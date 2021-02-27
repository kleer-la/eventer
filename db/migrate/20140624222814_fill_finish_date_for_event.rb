class FillFinishDateForEvent < ActiveRecord::Migration
  def up
  	Event.all.each do |ev|
  		if !ev.duration.nil? && ev.duration > 0
  			ev.finish_date = (ev.date + (ev.duration-1))
	  		begin
		  		ev.save!
	  		rescue => err
				puts "No se pudo actualizar el evento #{ev.id}: #{err}"
			end
		end
  	end
  end

  def down
  	Event.all.each do |ev|
  		ev.finish_date = nil
  		begin
	  		ev.save!
	  	rescue => err
			puts "No se pudo actualizar el evento #{ev.id}: #{err}"
		end
  	end
  end
end
