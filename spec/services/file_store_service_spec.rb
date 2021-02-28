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

  describe "S3", :slow => true do
    before(:all) do
      @fname= "12345.png"
      File.open(@fname, "w") { |f| f.write "xxx" }      
    end
    after(:all) do
      File.delete(@filename) if @filename.present?     
      File.delete(@fname)      
    end
    it "try to read from a S3 store - doesn't exists" do
      store= FileStoreService.createS3
      store.write @fname
      File.delete @fname
      @filename= store.read fname, "","certificates"

      expect(File.new(@filename).read).to eq "xxx"
    end
  end

end
