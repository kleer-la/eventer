require 'rails_helper'

describe FileStoreService do
  describe "Nullable" do
    it 'write to a Nullable store' do
      store= FileStoreService.createNull
      filename= store.write "12345.png"
      expect(filename).to include "12345.png"
    end

    it 'read from a Nullable store' do
      store= FileStoreService.createNull
      filename= store.read "12345.png", ""
      expect(filename).to include "12345.png"
    end

    it "try to read from a Nullable store - doesn't exists" do
      store= FileStoreService.createNull exists: {"certificate-images/12345.png" => false}
      expect {
        filename= store.read "12345.png", ""
      }.to raise_error ArgumentError
    end
  end

  describe "S3" do
    it 'write to a S3 store' do
      store= FileStoreService.createS3
      fname= store.tmp_path "12345.png"
      File.open(fname, "w") { |f| f.write " " }
      begin
        filename= store.write fname
      rescue AWS::Errors::MissingCredentialsError
        pending "Export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to ENV"
      end

      expect(filename).to include "12345.png"
    end

    # it "try to read from a S3 store - doesn't exists" do
    #   store= FileStoreService.createS3
    #   begin
    #   expect {
    #     filename= store.read "12345.png", ""
    #   }.to raise_error ArgumentError
    #   rescue AWS::Errors::MissingCredentialsError
    #     pending "Export  #AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to ENV"
    #   end
    # end
  end

end
