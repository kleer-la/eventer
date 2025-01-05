# lib/tasks/image_reference.rake
namespace :image_reference do
  desc 'List all models and fields configured with ImageReference'
  task list: :environment do
    # Ensure all models are loaded
    Rails.application.eager_load!

    puts "\nModels using ImageReference:\n"
    puts '=' * 50

    ImageUsageService.registered_models.sort_by(&:name).each do |model|
      puts "\n#{model.name}:"

      if model.image_url_fields.present?
        puts '  Direct URL fields:'
        model.image_url_fields.each do |field|
          puts "    - #{field}"
        end
      end

      next unless model.image_text_fields.present?

      puts '  Text fields with embedded images:'
      model.image_text_fields.each do |field|
        puts "    - #{field}"
      end
    end

    puts "\nTotal models: #{ImageUsageService.registered_models.count}"
  end
end
