# frozen_string_literal: true

class FindImageUsageTool < AuthenticatedTool
  tool_name 'find_image_usage'
  requires_permission :read, :images

  description <<~MD
    Says where an image is being used across the site — articles, resources,
    event types, and anything else that references images — matching both the
    dedicated image fields and mentions inside bodies.

    Takes the public URL of the image, or just its file name. Answer it before
    deleting or replacing an image: an unused image is safe to touch, one with
    references is not.
  MD

  arguments do
    required(:image).filled(:string).description('Public URL of the image, or its file name')
  end

  def call(image:)
    url = image.start_with?('http') ? image : FileStoreService.image_url(image, 'image')
    usage = ImageUsageService.find_usage(url)

    { image: url, used: usage.any?, usage: usage,
      models_searched: ImageUsageService.registered_models.map(&:name).compact.sort }.to_json
  end
end
