class MigrateEventWebinarsToModes < ActiveRecord::Migration
  def up
  	Event.where( "is_webinar = 't'" ).each do |e|
      if e.list_price > 0.0
    	 	e.mode = 'ol'
    	 	e.visibility_type = 'co'
      else
        e.mode = 'cl'
      end
    	e.save! unless !e.valid?
    end
  end

  def down
  	Event.where( "is_webinar = 't'" ).each do |e|
  		e.mode = nil
  		if e.list_price > 0.0 
  			e.visibility_type = 'co'
  		end
  		e.save! unless !e.valid?
  	end
  end
end
