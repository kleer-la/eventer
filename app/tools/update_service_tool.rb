# frozen_string_literal: true

class UpdateServiceTool < AuthenticatedTool
  tool_name 'update_service'
  requires_permission :update, Service

  description <<~MD
    Edits a service, looked up by slug or id. Only the fields you pass are
    touched. The page blocks are rich text, so HTML is accepted and replaces
    the whole block — read it with get_service first.

    To change part of a block, prefer `replacements`, which matches against that
    HTML. It patches value_proposition, outcomes, definitions, program, target,
    faq, card_description, recommended_way_summary and recommended_way_details.

    Two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    required(:id).filled(:string).description('Service slug (preferred) or numeric id')
    optional(:name).filled(:string).description('Service name')
    optional(:subtitle).filled(:string).description('One-line subtitle')
    optional(:service_area).filled(:string).description('Service area name it belongs to')
    optional(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    optional(:outcomes).filled(:string).description('Outcomes block; HTML accepted')
    optional(:definitions).filled(:string).description('Definitions block; HTML accepted')
    optional(:program).filled(:string).description('Program block; HTML accepted')
    optional(:target).filled(:string).description('Who it is for; HTML accepted')
    optional(:faq).filled(:string).description('FAQ block; HTML accepted')
    optional(:slug).filled(:string).description('URL slug')
    optional(:card_description).filled(:string).description('Short text for the listing card')
    optional(:pricing).filled(:string).description('Pricing note')
    optional(:side_image).filled(:string).description('Side image URL')
    optional(:brochure).filled(:string).description('Brochure URL')
    optional(:ordering).filled(:integer).description('Display order within the area')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:recommended_way_title).filled(:string).description('Recommended-way title')
    optional(:recommended_way_note).filled(:string).description('Recommended-way note')
    optional(:recommended_way_summary).filled(:string).description('Recommended-way summary')
    optional(:recommended_way_details).filled(:string).description('Recommended-way details')
    optional(:published).filled(:bool).description('Publish or unpublish it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, published: nil, service_area: nil, **fields)
    service = Service.friendly.find(id)
    ServiceWriteService.new(ability: ability, record: service, service_area: service_area,
                            published: published, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No service with slug or id #{id.inspect}"] }.to_json
  end
end
