# frozen_string_literal: true

require 'net/http'
require 'json'

namespace :pages do
  desc 'Sync a page from QA to this environment. Usage: rake pages:sync_from_qa[es]'
  task :sync_from_qa, [:lang] => :environment do |_t, args|
    lang = args[:lang] || 'es'
    qa_url = "https://qa.eventos.kleer.la/api/pages/#{lang}.json"

    puts "Fetching page data from #{qa_url}..."
    uri = URI(qa_url)
    response = Net::HTTP.get_response(uri)
    raise "Failed to fetch QA data: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)

    type_map = {
      'service' => 'Service',
      'article' => 'Article',
      'resource' => 'Resource',
      'event_type' => 'EventType'
    }

    page = Page.find_by!(lang: lang, slug: nil) # home page
    puts "Found page: #{page.display_name} (id=#{page.id})"

    ActiveRecord::Base.transaction do
      # Update page attributes
      page.update!(
        seo_title: data['seo_title'],
        seo_description: data['seo_description'],
        canonical: data['canonical'],
        cover: data['cover']
      )
      puts "Updated page attributes."

      # Replace sections
      page.sections.destroy_all
      data['sections'].each do |s|
        page.sections.create!(
          title: s['title'],
          content: s['content'],
          position: s['position'],
          slug: s['slug'],
          cta_text: s['cta_text'],
          cta_url: s['cta_url']
        )
      end
      puts "Replaced #{data['sections'].size} sections."

      # Replace recommended contents
      page.recommended_contents.destroy_all
      data['recommended'].each do |r|
        target_type = type_map[r['type']]
        raise "Unknown recommended type: #{r['type']}" unless target_type

        unless target_type.constantize.exists?(r['id'])
          puts "WARNING: #{target_type}##{r['id']} not found, skipping."
          next
        end

        page.recommended_contents.create!(
          target_type: target_type,
          target_id: r['id'],
          relevance_order: r['relevance_order']
        )
      end
      puts "Replaced #{data['recommended'].size} recommended contents."
    end

    puts "Done! Page '#{lang}' synced from QA."
  end
end
