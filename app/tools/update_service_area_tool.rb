# frozen_string_literal: true

class UpdateServiceAreaTool < AuthenticatedTool
  tool_name 'update_service_area'
  requires_permission :update, ServiceArea

  description <<~MD
    Edits a service area, looked up by slug or id. Only the fields you pass
    are touched. The page blocks are rich text, so HTML is accepted and
    replaces the whole block — read it with get_service_area first.

    To change part of a block, prefer `replacements`, which matches against
    that HTML. It patches summary, cta_message, slogan, subtitle, description,
    target, value_proposition, recommended_way_summary and
    recommended_way_details.

    Two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    required(:id).filled(:string).description('Service area slug (preferred) or numeric id')
    optional(:name).filled(:string).description('Service area name')
    optional(:slug).filled(:string).description('URL slug')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:icon).filled(:string).description('Icon image URL')
    optional(:primary_color).filled(:string).description('Primary color, e.g. "#68CEF2"')
    optional(:secondary_color).filled(:string).description('Secondary color, e.g. "#68CEF2"')
    optional(:primary_font_color).filled(:string).description('Primary button text color')
    optional(:secondary_font_color).filled(:string).description('Secondary button text color')
    optional(:summary).filled(:string).description('Summary block; HTML accepted')
    optional(:cta_message).filled(:string).description('Shown just before the buttons; HTML accepted')
    optional(:side_image).filled(:string).description('Side image URL')
    optional(:slogan).filled(:string).description('Slogan block; HTML accepted')
    optional(:subtitle).filled(:string).description('Subtitle block; HTML accepted')
    optional(:description).filled(:string).description('Description block; HTML accepted')
    optional(:target_title).filled(:string).description('Optional title for the target section')
    optional(:target).filled(:string).description('Who it is for; HTML accepted')
    optional(:value_proposition_title).filled(:string)
                                      .description('Optional title for the value proposition section')
    optional(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    optional(:ordering).filled(:integer).description('Display order')
    optional(:is_training_program).filled(:bool).description('true = it is a training program area')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:recommended_way_title).filled(:string).description('Recommended-way title')
    optional(:recommended_way_note).filled(:string).description('Recommended-way note')
    optional(:recommended_way_summary).filled(:string).description('Recommended-way summary')
    optional(:recommended_way_details).filled(:string).description('Recommended-way details')
    optional(:visible).filled(:bool).description('Show or hide it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, visible: nil, **fields)
    area = ServiceArea.friendly.find(id)
    ServiceAreaWriteService.new(ability: ability, record: area, visible: visible, **fields)
                           .call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No service area with slug or id #{id.inspect}"] }.to_json
  end
end
