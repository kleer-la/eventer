class AddFinishDateToEvent < ActiveRecord::Migration[4.2]
  def change
  	add_column :events, :finish_date, :date
  end
end
