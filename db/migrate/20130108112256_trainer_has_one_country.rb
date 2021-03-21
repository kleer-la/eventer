class TrainerHasOneCountry < ActiveRecord::Migration[4.2]
  def up
		add_column :trainers, :country_id, :integer
  end

	def down
		remove_column :trainers, :country_id
	end
end
