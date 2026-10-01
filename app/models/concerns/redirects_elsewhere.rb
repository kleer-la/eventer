# frozen_string_literal: true

# A page that left and sends its visitors to what replaces it: the site answers
# its URL with a 301 to `redirect_url`, a path (/es/servicios/otra) or an
# absolute URL — the same shape as Article#redirect_url and
# EventType#external_site_url (#224).
module RedirectsElsewhere
  extend ActiveSupport::Concern

  included do
    validates :redirect_url, format: { with: %r{\A(/|https?://)}, message: :must_be_path_or_url },
                             allow_blank: true
    # The admin form sends "" for an empty field; NULL answers "is there one?".
    before_validation { self.redirect_url = redirect_url&.strip.presence }

    scope :not_redirected, -> { where(redirect_url: nil) }
  end

  def redirected? = redirect_url.present?
end
