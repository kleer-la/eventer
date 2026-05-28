# frozen_string_literal: true

class AddTemplateAndShowInFooterToPages < ActiveRecord::Migration[8.1]
  def change
    # Distinguishes the two roles of Page:
    #   - "overlay" (default): the current behavior, where a Page provides
    #     section overrides for a known static-page template (e.g. an area
    #     landing's hero/contact). All existing Pages keep this behavior.
    #   - "flagship": a fully-authored standalone page rendered at
    #     /:lang/:slug, whose sections compose the body using the .rw-* kit.
    add_column :pages, :template, :string, default: 'overlay', null: false

    # When true, the page is surfaced in the global footer link list.
    add_column :pages, :show_in_footer, :boolean, default: false, null: false
  end
end
