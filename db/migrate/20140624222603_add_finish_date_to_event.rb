class AddFinishDateToEvent < ActiveRecord::Migration[5.0]
  def change
  	add_column :events, :finish_date, :date
  end
end
