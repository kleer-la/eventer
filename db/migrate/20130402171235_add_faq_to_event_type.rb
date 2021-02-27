class AddFaqToEventType < ActiveRecord::Migration[5.0]
  def up
		add_column :event_types, :faq, :text
	end
	
	def down
		remove_column :event_types, :faq
	end
end
