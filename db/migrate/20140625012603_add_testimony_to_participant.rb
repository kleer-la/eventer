class AddTestimonyToParticipant < ActiveRecord::Migration
  def change
  	add_column :participants, :testimony, :text
  end
end
