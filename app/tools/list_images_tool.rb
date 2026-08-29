# frozen_string_literal: true

class ListImagesTool < AuthenticatedTool
  tool_name 'list_images'
  requires_permission :read, :images

  DEFAULT_LIMIT = 50
  MAX_LIMIT = 200

  description <<~MD
    Lists the images stored for the site, newest first, with their public URL,
    size and when they were last modified. Use it to find the URL of an image
    you want to put in an article.

    Filters by name, extension and minimum size. The name filter is a plain
    substring, case insensitive.
  MD

  arguments do
    optional(:query).filled(:string).description('Substring matched against the file name')
    optional(:extension).filled(:string).description("File extension without the dot, e.g. 'gif' or 'webp'")
    optional(:min_size_kb).filled(:integer).description('Only images at least this big, in KB')
    optional(:limit).filled(:integer).description("How many to return (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
  end

  def call(query: nil, extension: nil, min_size_kb: nil, limit: DEFAULT_LIMIT)
    images = FileStoreService.current.list('image')
    images = images.select { |image| image.key.to_s.downcase.include?(query.downcase) } if query.present?
    images = images.select { |image| matches_extension?(image, extension) } if extension.present?
    images = images.select { |image| image.size.to_i >= min_size_kb * 1024 } if min_size_kb

    listed = images.sort_by { |image| image.last_modified.to_s }.reverse.first(limit.clamp(1, MAX_LIMIT))
    { count: listed.size, total_matching: images.size, images: listed.map { |image| summary(image) } }.to_json
  end

  private

  def matches_extension?(image, extension)
    File.extname(image.key.to_s).delete('.').downcase == extension.delete('.').downcase
  end

  def summary(image)
    { name: image.key, url: FileStoreService.image_url(image.key, 'image'),
      size_kb: (image.size.to_i / 1024.0).round(1), last_modified: image.last_modified }
  end
end
