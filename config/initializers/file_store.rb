Rails.application.config.to_prepare do
  FileStoreService.create_s3
end