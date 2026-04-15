class CreateServiceAreasTrainers < ActiveRecord::Migration[7.2]
  def change
    create_table :service_areas_trainers, id: false do |t|
      t.integer :service_area_id
      t.integer :trainer_id
    end
  end
end
