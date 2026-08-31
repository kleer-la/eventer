# frozen_string_literal: true

class CreateServiceTool < AuthenticatedTool
  tool_name 'create_service'
  requires_permission :create, Service

  description <<~MD
    Creates a service. It needs a service area and the blocks the page is built
    from: value proposition, outcomes, program and target are all required, and
    so is a side image. Those blocks are rich text, so HTML is accepted.

    Two steps: confirm=false (the default) previews without saving. It is
    created unpublished unless you pass published=true.
  MD

  arguments do
    required(:name).filled(:string).description('Service name')
    required(:subtitle).filled(:string).description('One-line subtitle')
    required(:service_area).filled(:string).description('Service area name it belongs to')
    required(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    required(:outcomes).filled(:string).description('Outcomes block; HTML accepted')
    required(:program).filled(:string).description('Program block; HTML accepted')
    required(:target).filled(:string).description('Who it is for; HTML accepted')
    required(:side_image).filled(:string).description('Side image URL')
    optional(:definitions).filled(:string).description('Definitions block; HTML accepted')
    optional(:faq).filled(:string).description('FAQ block; HTML accepted')
    optional(:slug).filled(:string).description('URL slug; derived from the name when omitted')
    optional(:card_description).filled(:string).description('Short text for the listing card')
    optional(:pricing).filled(:string).description('Pricing note')
    optional(:brochure).filled(:string).description('Brochure URL')
    optional(:ordering).filled(:integer).description('Display order within the area')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:published).filled(:bool).description('true = publish it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, published: false, service_area: nil, **fields)
    ServiceWriteService.new(ability: ability, service_area: service_area, published: published, **fields)
                       .call(confirm: confirm).to_json
  end
end
