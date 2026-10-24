# frozen_string_literal: true

# These files require a heavy gem (xero-ruby ~38 MiB, gruff ~6 MiB) that only a
# few code paths use. Keeping them out of eager loading means each Puma worker
# loads the gem the first time the constant is used, not at boot (#237).
Rails.autoloaders.main.do_not_eager_load(
  Rails.root.join('app/services/xero_client_service.rb'),
  Rails.root.join('app/services/xero_client_service'), # its null object, which reopens the module
  Rails.root.join('app/models/custom_spider.rb')
)
