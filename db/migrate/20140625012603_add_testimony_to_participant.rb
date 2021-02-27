class AddTestimonyToParticipant < ActiveRecord::Migration[5.0]
  def change
  	add_column :participants, :testimony, :text
  end
end
