class RefactorContactsTable < ActiveRecord::Migration[7.1]
  def change
    # Add new column for newsletter_added
    add_column :contacts, :newsletter_added, :boolean, default: false, null: false unless column_exists?(:contacts,
                                                                                                         :newsletter_added)

    # Rename suscribe to newsletter_opt_in
    rename_column :contacts, :suscribe, :newsletter_opt_in unless column_exists?(:contacts, :newsletter_opt_in)

    # Rename can_we_contact to content_updates_opt_in
    rename_column :contacts, :can_we_contact, :content_updates_opt_in unless column_exists?(:contacts,
                                                                                            :content_updates_opt_in)

    # Update status values (pending: 0, processed: 1, failed: 2, processing: 3)
    # to (pending: 0, in_progress: 1, completed: 2, failed: 3)
    reversible do |dir|
      dir.up do
        # Update existing data
        execute <<-SQL
            UPDATE contacts
            SET status = CASE
              WHEN status = 1 THEN 2  -- processed -> completed
              WHEN status = 3 THEN 1  -- processing -> in_progress
              ELSE status
            END
        SQL
      end
      dir.down do
        # Reverse the changes
        execute <<-SQL
            UPDATE contacts
            SET status = CASE
              WHEN status = 2 THEN 1  -- completed -> processed
              WHEN status = 1 THEN 3  -- in_progress -> processing
              ELSE status
            END
        SQL
      end
    end
  end
end
