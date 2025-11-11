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
    # Don't use has_rich_text here - we'll handle it manually
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

      # Get count before the select to avoid PostgreSQL COUNT issue
      total_count = MigrationParticipant
                    .joins(:event)
                    .where.not(testimony: [nil, ''])
                    .where(selected: true)
                    .count

      say "Found #{total_count} participant testimonies to import", true

      participants.find_each do |participant|
        # Create testimony record WITHOUT the testimony field (it's ActionText)
        testimony_record = MigrationTestimony.create!(
          first_name: participant.fname,
          last_name: participant.lname,
          photo_url: participant.photo_url,
          profile_url: participant.profile_url,
          stared: true,
          testimonial_type: 'EventType',
          testimonial_id: participant.event_type_id,
          created_at: participant.created_at,
          updated_at: participant.updated_at
        )

        # Manually insert into action_text_rich_texts table for the testimony content
        connection.execute(<<-SQL.squish)
          INSERT INTO action_text_rich_texts
            (name, body, record_type, record_id, created_at, updated_at)
          VALUES (
            'testimony',
            #{connection.quote(participant.testimony)},
            'Testimony',
            #{testimony_record.id},
            #{connection.quote(participant.created_at)},
            #{connection.quote(participant.updated_at)}
          )
        SQL

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
