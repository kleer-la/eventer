# frozen_string_literal: true

# The images stored for the site: one tool, three operations.
class ImagesTool < AuthenticatedTool
  tool_name 'images'
  requires_permission :read, :images

  OPERATIONS = %w[list find_usage upload].freeze
  DEFAULT_LIMIT = 50
  MAX_LIMIT = 200

  description <<~MD
    The images stored for the site.

    operation=list (default): newest first, with public URL, size and when
    last modified; filtered by query (a plain, case-insensitive substring of
    the file name), extension, min_size_kb. Use it to find the URL of an image
    to put in an article.
    operation=find_usage: where `image` (public URL or file name) is used
    across the site — articles, resources, event types, and anything else that
    references images — matching the dedicated image fields and mentions
    inside bodies. Answer it before deleting or replacing an image.
    operation=upload: stores an image that already lives at a public `url` — a
    GIF, PNG, JPEG, WebP or SVG — and returns the URL it gets on our side. This
    is the only way to add an image through this server: a file that only
    exists on your device has to go through the admin Images screen. Two
    steps: confirm=false (the default) fetches it, checks type and size and
    reports what would be stored; confirm=true uploads. Replacing an existing
    name needs overwrite=true, and replacing an image in use changes it
    everywhere at once — check with find_usage first. GIFs are stored as they
    are, so an animated one keeps its animation and its weight.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'find_usage' or 'upload'")
    optional(:query).filled(:string).description('list: substring matched against the file name')
    optional(:extension).filled(:string).description("list: file extension without the dot, e.g. 'gif' or 'webp'")
    optional(:min_size_kb).filled(:integer).description('list: only images at least this big, in KB')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:image).filled(:string).description('find_usage: public URL of the image, or its file name')
    optional(:url).filled(:string).description('upload: public http/https URL of the image to fetch')
    optional(:path).filled(:string).description('upload: file name to store it under; taken from the URL when omitted')
    optional(:overwrite).filled(:bool).description('upload: true = allow replacing an image with that name')
    optional(:confirm).filled(:bool).description('upload: false (default) = check only; true = store it')
  end

  # The operation is looked up in OPERATIONS before `send`, so only these three
  # methods are reachable from a client.
  def call(operation: 'list', **args)
    return unknown_operation(operation) unless OPERATIONS.include?(operation)

    send(operation, **args)
  end

  private

  def list(query: nil, extension: nil, min_size_kb: nil, limit: DEFAULT_LIMIT, **)
    images = FileStoreService.current.list('image')
    images = images.select { |img| img.key.to_s.downcase.include?(query.downcase) } if query.present?
    images = images.select { |img| matches_extension?(img, extension) } if extension.present?
    images = images.select { |img| img.size.to_i >= min_size_kb * 1024 } if min_size_kb

    listed = images.sort_by { |img| img.last_modified.to_s }.reverse.first(limit.clamp(1, MAX_LIMIT))
    listing(:images, listed.map { |img| summary(img) }, total: images.size, narrow: 'query, extension or min_size_kb')
  end

  def matches_extension?(image, extension)
    File.extname(image.key.to_s).delete('.').downcase == extension.delete('.').downcase
  end

  def summary(image)
    { name: image.key, url: FileStoreService.image_url(image.key, 'image'),
      size_kb: (image.size.to_i / 1024.0).round(1), last_modified: image.last_modified }
  end

  def find_usage(image: nil, **)
    return error('image is required: the public URL or the file name') if image.blank?

    url = image.start_with?('http') ? image : FileStoreService.image_url(image, 'image')
    usage = ImageUsageService.find_usage(url)
    { image: url, used: usage.any?, usage: usage,
      models_searched: ImageUsageService.registered_models.map(&:name).compact.sort }.to_json
  end

  def upload(url: nil, path: nil, overwrite: false, confirm: false, **)
    return unauthorized(:manage, :images) unless ability.can?(:manage, :images)
    return error('url is required: the public URL of the image to fetch') if url.blank?

    ImageImportService.new(url: url, path: path, overwrite: overwrite).call(confirm: confirm).to_json
  end
end
