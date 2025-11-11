class ConvertTestimoniesToPolymorphic < ActiveRecord::Migration[7.2]
  def up
    # Add polymorphic columns
    add_column :testimonies, :testimonial_type, :string
    add_column :testimonies, :testimonial_id, :integer

    # Migrate existing service_id data to polymorphic association
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE testimonies
          SET testimonial_type = 'Service',
              testimonial_id = service_id
          WHERE service_id IS NOT NULL
        SQL
      end
    end

    # Add indexes for polymorphic association
    add_index :testimonies, [:testimonial_type, :testimonial_id]

    # Remove old service_id column (but keep foreign key for now for safety)
    # We'll remove this in a later migration after validation
    # remove_column :testimonies, :service_id
  end

  def down
    # Restore service_id from polymorphic for Service testimonials
    reversible do |dir|
      dir.down do
        execute <<-SQL
          UPDATE testimonies
          SET service_id = testimonial_id
          WHERE testimonial_type = 'Service' AND testimonial_id IS NOT NULL
        SQL
      end
    end

    remove_index :testimonies, [:testimonial_type, :testimonial_id]
    remove_column :testimonies, :testimonial_id
    remove_column :testimonies, :testimonial_type
  end
end
