class AddFinishDateToEvent < ActiveRecord::Migration
  def change
  	add_column :events, :finish_date, :date
  end
end
