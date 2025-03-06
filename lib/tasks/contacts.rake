namespace :contacts do
  desc 'Generate assessment result for a specific contact'
  task :generate_assessment, [:contact_id] => :environment do |t, args|
    contact = Contact.find(args[:contact_id])
    puts "Generating assessment for contact #{contact.id} - #{contact.email}"

    GenerateAssessmentResultJob.perform_now(contact.id)

    puts "Assessment generation queued for contact #{contact.id}"
  rescue ActiveRecord::RecordNotFound
    puts "Error: Contact with ID #{args[:contact_id]} not found"
    # rescue StandardError => e
    #   puts "Error generating assessment: #{e.message}"
  end
end
