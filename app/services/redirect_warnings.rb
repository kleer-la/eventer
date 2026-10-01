# frozen_string_literal: true

# What a redirect_url does to a service or an area page, said in the preview:
# its URL answers 301 elsewhere and it leaves the area page, the menus and the
# sitemap (#224). And when one is unpublished or hidden without it, that its
# URL is about to answer 404 instead.
module RedirectWarnings
  private

  def redirect_warnings
    return [] unless @record.redirect_url_changed? && @record.redirected?

    ["Its URL will answer with a 301 to #{@record.redirect_url}#{redirect_reach}."]
  end

  def unpublishing_warning
    return super if @record.redirected?

    "#{super} If something replaces it, set redirect_url so its URL sends visitors there instead of a 404."
  end
end
