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
end
