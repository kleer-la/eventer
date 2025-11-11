class ImportParticipantTestimonies < ActiveRecord::Migration[7.2]
  # Disable transactions for this migration to allow for better progress reporting
  disable_ddl_transaction!

  def up
    # This migration imports participant testimonies into the new Testimony model
    # It only imports "selected" testimonies that are meant to be displayed publicly

    say_with_time "Importing participant testimonies to Testimony model" do
      count = 0

      # Use ActiveRecord to query - works across all databases
      # We need to use a raw query approach that's compatible with migrations
      connection.execute(<<-SQL.squish).each do |row|
        SELECT p.id, p.fname, p.lname, p.testimony, p.photo_url, p.profile_url,
               p.selected, e.event_type_id, p.created_at, p.updated_at
        FROM participants p
        INNER JOIN events e ON p.event_id = e.id
        WHERE p.testimony IS NOT NULL
          AND p.testimony != ''
          AND p.selected = #{connection.quoted_true}
        ORDER BY p.created_at DESC
      SQL

        # Use ActiveRecord's connection methods for database-agnostic inserts
        connection.insert(
          <<-SQL.squish,
            INSERT INTO testimonies
              (first_name, last_name, testimony, photo_url, profile_url, stared,
               testimonial_type, testimonial_id, created_at, updated_at)
            VALUES (
              #{connection.quote(row['fname'])},
              #{connection.quote(row['lname'])},
              #{connection.quote(row['testimony'])},
              #{connection.quote(row['photo_url'])},
              #{connection.quote(row['profile_url'])},
              #{connection.quoted_true},
              'EventType',
              #{row['event_type_id']},
              #{connection.quote(row['created_at'])},
              #{connection.quote(row['updated_at'])}
            )
          SQL
          'Testimony Create'
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
      count = connection.delete(
        "DELETE FROM testimonies WHERE testimonial_type = 'EventType'",
        'Remove EventType Testimonies'
      )
      say "Removed #{count} testimonies", true
      count
    end
  end
end
