# frozen_string_literal: true

# Renaming a slug moves a public URL. The old one keeps resolving (FriendlyId
# history plus the site's 301), but nothing rewrites the links people typed
# into the content, so a preview that changes a slug says what that entails.
module SlugChangeWarning
  private

  def slug_change_warnings(also: nil)
    return [] unless @record.persisted? && @record.slug_changed? && @record.slug_was.present?

    ["The slug changes from #{@record.slug_was.inspect} to #{@record.slug.inspect}#{also}. " \
     'The old URL keeps working: the site answers it with a 301 to the new one. Links written by ' \
     'hand in the content (cards, FAQ, articles) that use the old slug are not rewritten: update them.']
  end
end
