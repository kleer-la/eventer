# frozen_string_literal: true

class UpdateResourceTool < AuthenticatedTool
  tool_name 'update_resource'
  requires_permission :update, Resource

  description <<~MD
    Edits an existing resource, looked up by slug or id. Only the fields you
    pass are touched.

    Two steps: confirm=false (the default) validates and returns a preview of
    what would change, saving nothing; call again with confirm=true once the
    user agrees. Changing `published` needs publishing rights — a content user
    can edit but not publish, as in the admin screens.

    Fields ending in _es and _en are the Spanish and English sides of the same
    thing; the Spanish title and description are the required ones.

    To change part of a long text, prefer `replacements` over resending it. It
    patches long_description_es, long_description_en, comments_es and
    comments_en.
  MD

  arguments do
    required(:id).filled(:string).description('Resource slug (preferred) or numeric id')
    optional(:title_es).filled(:string).description('Spanish title, 2 to 100 characters')
    optional(:title_en).filled(:string).description('English title')
    optional(:description_es).filled(:string).description('Spanish summary, at most 220 characters')
    optional(:description_en).filled(:string).description('English summary')
    optional(:format).filled(:string)
                     .description('card | book | infographic | canvas | guide | game | assessment | video | other')
    optional(:category).filled(:string).description('Category name')
    optional(:slug).filled(:string).description('URL slug')
    optional(:long_description_es).filled(:string).description('Spanish long description')
    optional(:long_description_en).filled(:string).description('English long description')
    optional(:comments_es).filled(:string).description('Spanish notes shown on the page')
    optional(:comments_en).filled(:string).description('English notes shown on the page')
    optional(:cover_es).filled(:string).description('Spanish cover image URL')
    optional(:cover_en).filled(:string).description('English cover image URL')
    optional(:getit_es).filled(:string).description('Spanish download link; having one makes it downloadable')
    optional(:getit_en).filled(:string).description('English download link')
    optional(:buyit_es).filled(:string).description('Spanish purchase link')
    optional(:buyit_en).filled(:string).description('English purchase link')
    optional(:landing_es).filled(:string).description('Spanish landing page URL')
    optional(:landing_en).filled(:string).description('English landing page URL')
    optional(:preview_es).filled(:string).description('Spanish preview link')
    optional(:preview_en).filled(:string).description('English preview link')
    optional(:share_text_es).filled(:string).description('Spanish sharing text')
    optional(:share_text_en).filled(:string).description('English sharing text')
    optional(:tags_es).filled(:string).description('Spanish tags')
    optional(:tags_en).filled(:string).description('English tags')
    optional(:seo_description_es).filled(:string).description('Spanish SEO description')
    optional(:seo_description_en).filled(:string).description('English SEO description')
    optional(:tabtitle_es).filled(:string).description('Spanish browser tab title')
    optional(:tabtitle_en).filled(:string).description('English browser tab title')
    optional(:published).filled(:bool).description('Publish or unpublish. Needs publishing rights')
    optional(:confirm).filled(:bool).description('false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(id:, confirm: false, **fields)
    resource = Resource.friendly.find(id)
    ResourceWriteService.new(ability: ability, record: resource, **fields).call(confirm: confirm).to_json
  rescue ActiveRecord::RecordNotFound
    { status: 'error', errors: ["No resource with slug or id #{id.inspect}"] }.to_json
  end
end
