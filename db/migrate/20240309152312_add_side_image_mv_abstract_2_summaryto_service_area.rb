class AddSideImageMvAbstract2SummarytoServiceArea < ActiveRecord::Migration[7.1]
  def up
    # Add the side_image column to service_areas table
    add_column :service_areas, :side_image, :string

    # Update only the records related to ServiceArea model
    # from 'abstract' to 'summary'
    ActionText::RichText.where(name: 'abstract', record_type: 'ServiceArea').update_all(name: 'summary')
  end

  def down
    # Remove the side_image column from service_areas table
    remove_column :service_areas, :side_image

    # Revert the ActionText records from 'summary' back to 'abstract'
    ActionText::RichText.where(name: 'summary', record_type: 'ServiceArea').update_all(name: 'abstract')
  end
end
