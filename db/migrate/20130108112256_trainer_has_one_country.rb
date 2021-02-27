class TrainerHasOneCountry < ActiveRecord::Migration
  def up
		add_column :trainers, :country_id, :integer
  end

	def down
		remove_column :trainers, :country_id
	end
end
