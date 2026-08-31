# frozen_string_literal: true

require 'rails_helper'

describe FileStoreService do
  # The images bucket lives in sa-east-1 and the legacy one in us-east-1. Aiming
  # a client at the wrong region survives a GET (S3 redirects) but makes every
  # HEAD fail with a bare 400, which broke exists? on the images bucket while
  # listing kept working.
  describe S3FileStore do
    let(:store) { S3FileStore.new(access_key_id: 'key', secret_access_key: 'secret') }

    it 'reaches each bucket through a client pinned to its own region' do
      expect(store.objects('animado.gif', 'kleer-images').client.config.region).to eq('sa-east-1')
      expect(store.objects('certificate-images/x.png').client.config.region).to eq('us-east-1')
    end

    it 'reuses one client per region instead of building one per call' do
      expect(store.objects('a.gif', 'kleer-images').client)
        .to equal(store.objects('b.gif', 'kleer-images').client)
    end
  end

  describe '#upload' do
    it 'reports the upload even when the bucket refuses per-object ACLs' do
      # Object Ownership set to bucket owner enforced: the object is stored and
      # public by policy, but PutObjectAcl comes back denied.
      allow_any_instance_of(NullStoreObjectAcl).to receive(:put)
        .and_raise(Aws::S3::Errors::AccessDenied.new(nil, 'Access Denied'))

      url = FileStoreService.create_null.upload(Tempfile.new('x'), 'animado.gif', 'image')

      expect(url).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/animado.gif')
    end

    it 'tells S3 what the file is, so it is not served as octet-stream' do
      expect_any_instance_of(NullStoreObject).to receive(:upload_file)
        .with(anything, content_type: 'audio/mpeg')

      FileStoreService.create_null.upload(Tempfile.new('x'), 'article_1.mp3', 'image')
    end

    it 'falls back to octet-stream for an extension it does not know' do
      expect_any_instance_of(NullStoreObject).to receive(:upload_file)
        .with(anything, content_type: 'application/octet-stream')

      FileStoreService.create_null.upload(Tempfile.new('x'), 'raro.qqq', 'image')
    end
  end

  describe '.image_url' do
    context 'when image_name contains special characters' do
      it 'properly encodes accents and spaces for image type' do
        image_name = 'Guía para mejora Lean.webp'
        
        result = FileStoreService.image_url(image_name, 'image')
        
        expect(result).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/Gu%C3%ADa+para+mejora+Lean.webp')
      end
      
      it 'properly encodes special characters for certificate type' do
        image_name = 'Diseño de la Agilidad.pdf'
        
        result = FileStoreService.image_url(image_name, 'certificate')
        
        expect(result).to eq('https://s3.amazonaws.com/Keventer/certificate-images/Dise%C3%B1o+de+la+Agilidad.pdf')
      end
      
      it 'handles nil image_name gracefully' do
        result = FileStoreService.image_url(nil, 'image')
        
        expect(result).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/')
      end
      
      it 'handles empty image_name' do
        result = FileStoreService.image_url('', 'image')
        
        expect(result).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/')
      end
    end
  end

  describe 'Nullable' do
    it 'write to a Nullable store' do
      store = FileStoreService.create_null
      filename = store.write '12345.png'
      expect(filename).to include '12345.png'
    end

    it 'read from a Nullable store' do
      store = FileStoreService.create_null
      filename = store.read '12345.png', ''
      expect(filename).to include '12345.png'
    end

    it "try to read from a Nullable store - doesn't exists" do
      store = FileStoreService.create_null exists: { 'certificate-images/12345.png' => false }
      expect do
        store.read '12345.png', ''
      end.to raise_error ArgumentError
    end
  end

  describe 'S3', slow: true do
    before(:all) do
      @fname = '12345.png'
      File.open(@fname, 'w') { |f| f.write 'xxx' }
    end
    after(:all) do
      File.delete(@filename) if @filename.present?
      File.delete(@fname)    if File.exist? @fname
    end
    it "try to read from a S3 store - doesn't exists" do
      store = FileStoreService.create_s3
      store.write @fname
      File.delete @fname
      @filename = store.read @fname, '', 'certificates'

      expect(File.new(@filename).read).to eq 'xxx'
    end
  end
end
