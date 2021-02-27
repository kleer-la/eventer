class AddRatingAtributesToTrainer < ActiveRecord::Migration
  def change
  	add_column :trainers, :average_rating, :decimal, :precision => 4, :scale => 2
  	add_column :trainers, :net_promoter_score, :integer
  	add_column :trainers, :surveyed_count, :integer
  	add_column :trainers, :promoter_count, :integer
  end
end
