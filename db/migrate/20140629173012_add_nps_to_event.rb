class AddNpsToEvent < ActiveRecord::Migration
  def change
  	add_column :events, :net_promoter_score, :integer
  end
end
