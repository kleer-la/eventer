# frozen_string_literal: true

class CreateResourceTool < AuthenticatedTool
  tool_name 'create_resource'
  requires_permission :create, Resource

  description <<~MD
    Creates a resource (book, infographic, canvas, guide, game, video…). It is
    created unpublished unless you pass published=true, which needs publishing
    rights.

    Two steps: confirm=false (the default) validates and previews without
    saving; call again with confirm=true once the user agrees. The slug is
    derived from the Spanish title when you do not pass one.

    Only the Spanish side is required; leaving the English side empty means the
    resource shows untranslated on the English site, and the preview says so.
    Everything not offered here can be filled in afterwards with update_resource.
  MD

  arguments do
    required(:title_es).filled(:string).description('Spanish title, 2 to 100 characters')
    required(:description_es).filled(:string).description('Spanish summary, at most 220 characters')
    required(:format).filled(:string)
                     .description('card | book | infographic | canvas | guide | game | assessment | video | other')
    optional(:title_en).filled(:string).description('English title')
    optional(:description_en).filled(:string).description('English summary')
    optional(:category).filled(:string).description('Category name')
    optional(:slug).filled(:string).description('URL slug; derived from the Spanish title when omitted')
    optional(:long_description_es).filled(:string).description('Spanish long description')
    optional(:long_description_en).filled(:string).description('English long description')
    optional(:cover_es).filled(:string).description('Spanish cover image URL')
    optional(:cover_en).filled(:string).description('English cover image URL')
    optional(:getit_es).filled(:string).description('Spanish download link; having one makes it downloadable')
    optional(:getit_en).filled(:string).description('English download link')
    optional(:buyit_es).filled(:string).description('Spanish purchase link')
    optional(:buyit_en).filled(:string).description('English purchase link')
    optional(:landing_es).filled(:string).description('Spanish landing page URL')
    optional(:landing_en).filled(:string).description('English landing page URL')
    optional(:tags_es).filled(:string).description('Spanish tags')
    optional(:tags_en).filled(:string).description('English tags')
    optional(:published).filled(:bool).description('Publish on creation. Needs publishing rights')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
  end

  def call(confirm: false, **fields)
    ResourceWriteService.new(ability: ability, **fields).call(confirm: confirm).to_json
  end
end
