class TrainerHasOneCountry < ActiveRecord::Migration[5.0]
  def up
		add_column :trainers, :country_id, :integer
  end

	def down
		remove_column :trainers, :country_id
	end
end
