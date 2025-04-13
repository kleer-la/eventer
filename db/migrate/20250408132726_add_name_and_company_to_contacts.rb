class AddNameAndCompanyToContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :contacts, :name, :string
    add_column :contacts, :company, :string

    Contact.reset_column_information

    Contact.find_each do |contact|
      contact.update_columns(
        name: contact.form_data&.dig('name'),
        company: contact.form_data&.dig('company')
      )
    end
  end
end
