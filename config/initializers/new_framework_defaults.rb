# frozen_string_literal: true

# Legacy overrides kept from Rails 5.0 upgrade.
# These deviate from modern Rails defaults intentionally.

# Disable per-form CSRF tokens (legacy behavior).
Rails.application.config.action_controller.per_form_csrf_tokens = false

# Disable origin-checking CSRF mitigation (legacy behavior).
Rails.application.config.action_controller.forgery_protection_origin_check = false

# Do not require belongs_to associations by default — existing data has nullable FKs.
Rails.application.config.active_record.belongs_to_required_by_default = false
