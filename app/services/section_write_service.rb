# frozen_string_literal: true

# A section of a page — a block of a flagship, or an override of an overlay
# template. It is edited inside its page in the admin, so that is where the
# saved result points.
class SectionWriteService < ContentWriteService
  self.model = Section
  self.editable_fields = %i[slug title content cta_text cta_url position]
  self.long_fields = %i[content]
  self.publication_flag = nil

  private

  def admin_path = "/admin/pages/#{@record.page_id}"

  # An overlay's sections are read by slug in website17's template, so a slug
  # it does not read saves and never shows (#243). Said when the slug is set,
  # not on every edit of a section that already has it.
  def model_warnings
    page = @record.page
    return [] unless page&.overlay? && (@record.new_record? || @record.slug_changed?)
    return ["website17 does not load an overlay with slug #{page.slug.inspect}: no section of it shows."] \
      if OverlayTemplate.unknown?(page)

    template = OverlayTemplate.for(page)
    return [] if template.reads?(@record.slug)

    [unread_slug_warning(template)]
  end

  def unread_slug_warning(template)
    reads = template.sections.keys
    known = reads.any? ? "It reads: #{reads.join(', ')}." : template.note
    "The template of this page does not read a section '#{@record.slug}': it will not show on the site. #{known}"
  end
end
