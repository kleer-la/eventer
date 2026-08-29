# frozen_string_literal: true

class UploadImageFromUrlTool < AuthenticatedTool
  tool_name 'upload_image_from_url'
  requires_permission :manage, :images

  description <<~MD
    Stores an image that already lives at a public URL — a GIF, PNG, JPEG, WebP
    or SVG — and returns the URL it gets on our side, ready to drop into an
    article.

    This is the only way to add an image through this server: a file that only
    exists on your device has to go through the admin Images screen, because a
    tool call cannot carry the bytes of an attachment.

    Two steps: confirm=false (the default) fetches it, checks type and size and
    reports what would be stored without storing anything; call again with
    confirm=true to upload. Replacing an existing name needs overwrite=true, and
    replacing an image that is already in use changes it everywhere at once —
    check with find_image_usage first.

    GIFs are stored as they are, with no WebP conversion, so an animated one
    keeps its animation and its weight.
  MD

  arguments do
    required(:url).filled(:string).description('Public http/https URL of the image to fetch')
    optional(:path).filled(:string).description('File name to store it under; taken from the URL when omitted')
    optional(:overwrite).filled(:bool).description('true = allow replacing an image with that name')
    optional(:confirm).filled(:bool).description('false (default) = check only; true = store it')
  end

  def call(url:, path: nil, overwrite: false, confirm: false)
    ImageImportService.new(url: url, path: path, overwrite: overwrite).call(confirm: confirm).to_json
  end
end
