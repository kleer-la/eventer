class RemoveServiceIdFromTestimonies < ActiveRecord::Migration[7.2]
  def change
    remove_column :testimonies, :service_id, :integer
  end
end
