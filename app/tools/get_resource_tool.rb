# frozen_string_literal: true

class GetResourceTool < AuthenticatedTool
  tool_name 'get_resource'
  requires_permission :read, Resource

  description <<~MD
    Returns one resource in full — both languages, links, tags, credits and the
    contents it recommends — looked up by slug or id. Read it before editing,
    so the change is made against what is actually there.
  MD

  arguments do
    required(:id).filled(:string).description('Resource slug (preferred) or numeric id')
  end

  def call(id:)
    resource = Resource.friendly.find(id)
    { id: resource.id, slug: resource.slug, format: resource.format, published: resource.published,
      category: resource.category_name, downloadable: resource.downloadable,
      es: side(resource, 'es'), en: side(resource, 'en'),
      authors: resource.authors.map(&:name), translators: resource.translators.map(&:name),
      illustrators: resource.illustrators.map(&:name),
      recommends: resource.recommended_contents.includes(:target).map { |content| recommendation(content) },
      updated_at: resource.updated_at }.to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No resource with slug or id #{id.inspect}"] }.to_json
  end

  private

  def side(resource, lang)
    %w[title description long_description comments cover getit buyit landing preview
       share_text tags seo_description tabtitle].to_h do |field|
      [field, resource.public_send("#{field}_#{lang}")]
    end
  end

  def recommendation(content)
    { target_type: content.target_type, target_id: content.target_id,
      target: content.target&.try(:title) || content.target&.try(:name),
      relevance_order: content.relevance_order }
  end
end
