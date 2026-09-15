# frozen_string_literal: true

class CreateServiceAreaTool < AuthenticatedTool
  tool_name 'create_service_area'
  requires_permission :create, ServiceArea

  description <<~MD
    Creates a service area: the group a Service belongs to, with its own page
    (summary, slogan, subtitle, description, target, value proposition, CTA
    message), palette and icon. Those, plus side image and SEO title/description,
    are all required. The page blocks are rich text, so HTML is accepted.

    Two steps: confirm=false (the default) previews without saving. It is
    created hidden unless you pass visible=true.
  MD

  arguments do
    required(:name).filled(:string).description('Service area name')
    required(:summary).filled(:string).description('Summary block; HTML accepted')
    required(:icon).filled(:string).description('Icon image URL')
    required(:slogan).filled(:string).description('Slogan block; HTML accepted')
    required(:subtitle).filled(:string).description('Subtitle block; HTML accepted')
    required(:description).filled(:string).description('Description block; HTML accepted')
    required(:side_image).filled(:string).description('Side image URL')
    required(:primary_color).filled(:string).description('Primary color, e.g. "#68CEF2"')
    required(:secondary_color).filled(:string).description('Secondary color, e.g. "#68CEF2"')
    required(:cta_message).filled(:string).description('Shown just before the buttons; HTML accepted')
    required(:seo_title).filled(:string).description('SEO title')
    required(:seo_description).filled(:string).description('SEO description')
    optional(:slug).filled(:string).description('URL slug; derived from the name when omitted')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:primary_font_color).filled(:string).description('Primary button text color')
    optional(:secondary_font_color).filled(:string).description('Secondary button text color')
    optional(:target_title).filled(:string).description('Optional title for the target section')
    optional(:target).filled(:string).description('Who it is for; HTML accepted')
    optional(:value_proposition_title).filled(:string)
                                      .description('Optional title for the value proposition section')
    optional(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    optional(:ordering).filled(:integer).description('Display order')
    optional(:is_training_program).filled(:bool).description('true = it is a training program area')
    optional(:recommended_way_title).filled(:string).description('Recommended-way title')
    optional(:recommended_way_note).filled(:string).description('Recommended-way note')
    optional(:recommended_way_summary).filled(:string).description('Recommended-way summary')
    optional(:recommended_way_details).filled(:string).description('Recommended-way details')
    optional(:visible).filled(:bool).description('true = show it on the site')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, visible: false, **fields)
    ServiceAreaWriteService.new(ability: ability, visible: visible, **fields).call(confirm: confirm).to_json
  end
end
