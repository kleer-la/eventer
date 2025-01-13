class AddFieldsToContacts < ActiveRecord::Migration[7.1]
  def up
    # Add new columns
    add_column :contacts, :resource_slug, :string
    add_column :contacts, :can_we_contact, :boolean, default: false
    add_column :contacts, :suscribe, :boolean, default: false

    # Add index for resource_slug
    add_index :contacts, :resource_slug

    # Initialize data from form_data
    Contact.find_each do |contact|
      contact.update_columns(
        resource_slug: contact.form_data['resource_slug'],
        can_we_contact: !!contact.form_data['can_we_contact'],
        suscribe: !!contact.form_data['suscribe']
      )
    end
  end

  def down
    remove_index :contacts, :resource_slug
    remove_column :contacts, :suscribe
    remove_column :contacts, :can_we_contact
    remove_column :contacts, :resource_slug
  end
end
