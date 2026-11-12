# frozen_string_literal: true

# The images stored for the site: one tool, three operations.
class ImagesTool < AuthenticatedTool
  tool_name 'images'
  requires_permission :read, :images

  OPERATIONS = %w[list find_usage upload upload_slot delete].freeze
  # QA (the environment that copies from production) stores its images in the
  # production bucket, but only sees its own content.
  SHARED_BUCKET = 'Not on QA: it shares the image bucket with production, and an image unused here may be ' \
                  'on a production page. Delete it from production, where its usage can be checked.'
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
    operation=upload_slot: for a file that only exists on your machine. Give
    the file name in `path`; it answers a presigned `put_url` to PUT the file
    to within #{FileStoreService::SLOT_MINUTES} minutes (the `upload_with` command does it,
    if you can run a shell), and in `then` the arguments of the upload that
    takes it from there. Without a shell, use the admin Images screen.
    operation=upload: stores an image that lives at a `url` — a GIF, PNG,
    JPEG, WebP or SVG, at a public URL or put through upload_slot — and returns
    the URL it gets on our side. A file put through upload_slot is dropped
    from its staging place once stored. Two
    steps: confirm=false (the default) fetches it, checks type and size and
    reports what would be stored; confirm=true uploads. Replacing an existing
    name needs overwrite=true, and replacing an image in use changes it
    everywhere at once — check with find_usage first. A PNG or JPEG also gets
    a WebP twin (same name, .webp) unless convert_to_webp=false; GIFs are stored
    as they are, so an animated one keeps its animation and its weight.
    `path` may include folders (news/foto.png). The preview gives width and
    height and warns about an image over 300 KB or 1600 px wide: max_width
    scales a PNG, JPEG or WebP down before it is stored.
    operation=delete: removes the stored `image` (file name or URL). It is
    refused while anything uses it — the answer says where, as find_usage
    would. Two steps: confirm=false (the default) says what would go;
    confirm=true deletes it. A WebP twin is a file of its own. Production
    only: QA shares the bucket but not the content that uses it.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'find_usage', 'upload', 'upload_slot' " \
                                                     "or 'delete'")
    optional(:query).filled(:string).description('list: substring matched against the file name')
    optional(:extension).filled(:string).description("list: file extension without the dot, e.g. 'gif' or 'webp'")
    optional(:min_size_kb).filled(:integer).description('list: only images at least this big, in KB')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:image).filled(:string).description('find_usage/delete: public URL of the image, or its file name')
    optional(:url).filled(:string).description('upload: public http/https URL of the image to fetch')
    optional(:path).filled(:string).description('upload: file name to store it under; taken from the URL when ' \
                                                'omitted. upload_slot: the name of the file (required)')
    optional(:overwrite).filled(:bool).description('upload: true = allow replacing an image with that name')
    optional(:convert_to_webp).filled(:bool).description('upload: also store a WebP twin of a PNG/JPEG (default true)')
    optional(:max_width).filled(:integer).description('upload: scale a wider PNG, JPEG or WebP down to this ' \
                                                      'many pixels before storing it (1600 suits any page)')
    optional(:confirm).filled(:bool).description('upload/delete: false (default) = check only; true = do it')
  end

  # The operation is looked up in OPERATIONS before `send`, so only these
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

    key = FileStoreService.image_key(image)
    url = key ? FileStoreService.image_url(key, 'image') : image
    usage = usage_of(key, image)
    { image: url, used: usage.any?, usage: usage,
      models_searched: ImageUsageService.registered_models.map(&:name).compact.sort }.to_json
  end

  def usage_of(key, image)
    ImageUsageService.find_usage(key ? FileStoreService.image_url_variants(key) : [image])
  end

  def delete(image: nil, confirm: false, **)
    return unauthorized(:manage, :images) unless ability.can?(:manage, :images)

    key = FileStoreService.image_key(image)
    refusal = delete_refusal(image, key)
    return error(refusal) if refusal

    usage = usage_of(key, image)
    usage.any? ? in_use(key, usage) : deletion(key, confirm)
  end

  def delete_refusal(image, key)
    if ArticleProductionCopy.source then SHARED_BUCKET
    elsif image.blank? then 'image is required: the public URL or the file name'
    elsif key.blank? || key.end_with?('/') then "#{image} is not in the image bucket"
    elsif !FileStoreService.current.exists?(key) then "#{key} does not exist, so there is nothing to delete"
    end
  end

  def in_use(key, usage)
    { status: 'error', usage: usage, errors: ["#{key} is in use; point those at another image first"] }.to_json
  end

  def deletion(key, confirm)
    answer = { file_name: key, url: FileStoreService.image_url(key, 'image') }
    unless confirm
      return answer.merge(status: 'preview', note: 'Nothing was deleted. Call again with confirm=true.').to_json
    end

    FileStoreService.current.delete(key)
    answer.merge(status: 'deleted', note: 'The CDN may keep serving it for up to 24 h.').to_json
  end

  def upload(url: nil, path: nil, overwrite: false, convert_to_webp: true, max_width: nil, confirm: false, **)
    return unauthorized(:manage, :images) unless ability.can?(:manage, :images)
    return error('url is required: the public URL of the image to fetch') if url.blank?

    result = ImageImportService.new(url: url, path: path, overwrite: overwrite, convert_to_webp: convert_to_webp,
                                    max_width: max_width).call(confirm: confirm)
    drop_staging_copy(url) if result[:status] == 'saved'
    result.to_json
  end

  def upload_slot(path: nil, **)
    return unauthorized(:manage, :images) unless ability.can?(:manage, :images)
    return error('path is required: the name of the file, e.g. portada.png') if path.blank?

    slot = FileStoreService.current.upload_slot(path)
    { status: 'ready', put_url: slot[:put_url], expires_in_minutes: FileStoreService::SLOT_MINUTES,
      upload_with: "curl -sS --fail -T <local file> '#{slot[:put_url]}'",
      then: { operation: 'upload', url: slot[:get_url], path: path },
      note: 'PUT the file to put_url, then call images with the arguments in `then` (confirm=false to check it, ' \
            'then confirm=true to store it).' }.to_json
  end

  def drop_staging_copy(url)
    key = FileStoreService.current.incoming_key(url)
    FileStoreService.current.delete(key) if key
  end
end
