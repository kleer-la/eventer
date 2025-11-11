class ImportParticipantTestimonies < ActiveRecord::Migration[7.2]
  # Disable transactions for this migration to allow for better progress reporting
  disable_ddl_transaction!

  # Define minimal models within migration to avoid dependencies on app code
  class MigrationParticipant < ActiveRecord::Base
    self.table_name = 'participants'
    belongs_to :event, class_name: 'ImportParticipantTestimonies::MigrationEvent', foreign_key: 'event_id'
  end

  class MigrationEvent < ActiveRecord::Base
    self.table_name = 'events'
  end

  class MigrationTestimony < ActiveRecord::Base
    self.table_name = 'testimonies'
    has_rich_text :testimony
  end

  def up
    # This migration imports participant testimonies into the new Testimony model
    # It only imports "selected" testimonies that are meant to be displayed publicly

    say_with_time "Importing participant testimonies to Testimony model" do
      count = 0

      # Query participants with testimonies
      participants = MigrationParticipant
                     .joins(:event)
                     .where.not(testimony: [nil, ''])
                     .where(selected: true)
                     .select('participants.*, events.event_type_id')
                     .order(created_at: :desc)

      say "Found #{participants.count} participant testimonies to import", true

      participants.find_each do |participant|
        # Create testimony using ActiveRecord to properly handle ActionText
        MigrationTestimony.create!(
          first_name: participant.fname,
          last_name: participant.lname,
          testimony: participant.testimony, # ActionText will handle this properly
          photo_url: participant.photo_url,
          profile_url: participant.profile_url,
          stared: true,
          testimonial_type: 'EventType',
          testimonial_id: participant.event_type_id,
          created_at: participant.created_at,
          updated_at: participant.updated_at
        )
        count += 1

        # Progress indicator for large datasets
        say "Imported #{count} testimonies...", true if (count % 50).zero?
      end

      say "Imported #{count} participant testimonies total", true
      count
    end
  end

  def down
    # Remove imported testimonies (those associated with EventType)
    say_with_time "Removing imported participant testimonies" do
      # Use delete_all to avoid loading ActionText associations
      count = connection.execute(
        "DELETE FROM testimonies WHERE testimonial_type = 'EventType'"
      )

      # Also clean up ActionText records for EventType testimonies
      connection.execute(<<-SQL.squish)
        DELETE FROM action_text_rich_texts
        WHERE record_type = 'Testimony'
        AND record_id NOT IN (SELECT id FROM testimonies)
      SQL

      say "Removed EventType testimonies", true
      count
    end
  end
end
