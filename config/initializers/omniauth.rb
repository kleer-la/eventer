# frozen_string_literal: true

# OmniAuth builds the Google redirect_uri from the request's host, which Rails
# takes from Host or X-Forwarded-Host. kamal-proxy only routes these hosts
# (config/deploy.yml, config/deploy.qa.yml), but X-Forwarded-Host could still be
# forged (CVE-2026-63183), so production only accepts them. Keep both lists in
# step: spec/requests/omniauth_hosts_spec.rb fails when they differ.
OMNIAUTH_ALLOWED_HOSTS = %w[
  eventos.kleer.la handoff.kleer.la
  qa.eventos.kleer.la qa.handoff.kleer.la
].freeze

OmniAuth.config.allowed_hosts = OMNIAUTH_ALLOWED_HOSTS if Rails.env.production?
