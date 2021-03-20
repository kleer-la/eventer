class AddNpsToEvent < ActiveRecord::Migration[4.2]
  def change
  	add_column :events, :net_promoter_score, :integer
  end
end
