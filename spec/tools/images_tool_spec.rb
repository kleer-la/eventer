# frozen_string_literal: true

require 'rails_helper'

# The images stored for the site: one tool, four operations. The store is the
# null one (FileStoreService.create_null), so nothing reaches S3; fetching and
# checking an image at a URL is ImageImportService's job, covered over MCP in
# spec/requests/mcp_images_spec.rb, so here it is a double and these examples
# pin what the tool itself decides around it.
describe ImagesTool do
  let(:user) { FactoryBot.create(:content_user) }
  let(:bucket) { 'https://kleer-images.s3.sa-east-1.amazonaws.com' }

  def run(**args)
    tool = described_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'operation=list (the default)' do
    before do
      FileStoreService.create_null(files: [
                                     { key: 'Portada.WEBP', size: 40_960,
                                       last_modified: Time.zone.parse('2026-08-25') },
                                     { key: 'demo animado.gif', size: 2_048_000,
                                       last_modified: Time.zone.parse('2026-08-20') },
                                     { key: 'viejo-logo.png', size: 5_120,
                                       last_modified: Time.zone.parse('2026-01-05') },
                                     { key: 'incoming/abc/subiendo.png', size: 1_024,
                                       last_modified: Time.zone.parse('2026-09-01') }
                                   ])
    end

    it 'lists them newest first, with public URL and size, leaving staging copies out' do
      result = run

      expect(result).to include('returned' => 3, 'total' => 3)
      expect(result['images'].pluck('name')).to eq(['Portada.WEBP', 'demo animado.gif', 'viejo-logo.png'])
      expect(result['images'].second).to include('url' => "#{bucket}/demo+animado.gif", 'size_kb' => 2000.0)
    end

    it 'matches the name and the extension in any case, with or without the dot' do
      expect(run(query: 'portada')['images'].pluck('name')).to eq(['Portada.WEBP'])
      expect(run(extension: 'webp')['images'].pluck('name')).to eq(['Portada.WEBP'])
      expect(run(extension: '.GIF')['images'].pluck('name')).to eq(['demo animado.gif'])
    end

    it 'keeps only the images at least min_size_kb big' do
      expect(run(min_size_kb: 40)['images'].pluck('name')).to eq(['Portada.WEBP', 'demo animado.gif'])
    end

    it 'caps the listing with limit and says what it left out' do
      result = run(limit: 1)

      expect(result).to include('returned' => 1, 'total' => 3, 'truncated' => true)
      expect(result['note']).to include('query, extension or min_size_kb', 'max 200')
    end
  end

  describe 'operation=find_usage' do
    let(:url) { "#{bucket}/portada.png" }

    it 'finds where the image is used, by URL or by file name' do
      article = FactoryBot.create(:article, title: 'Con portada', cover: url)

      result = run(operation: 'find_usage', image: 'portada.png')

      expect(result).to include('image' => url, 'used' => true)
      expect(result['usage'].to_s).to include(article.id.to_s)
      expect(result['models_searched']).to include('Article')
      expect(run(operation: 'find_usage', image: url)['used']).to be true
    end

    it 'says so when nothing uses it' do
      expect(run(operation: 'find_usage', image: 'huerfana.png')).to include('used' => false, 'usage' => {})
    end

    it 'needs to know which image' do
      expect(run(operation: 'find_usage')['errors'].join).to include('image is required')
    end
  end

  describe 'operation=upload' do
    let(:source) { 'https://images.example.com/foto.png' }
    let(:import) { instance_double(ImageImportService) }

    before do
      FileStoreService.create_null
      allow(FileStoreService.current).to receive(:delete)
      allow(ImageImportService).to receive(:new).and_return(import)
    end

    it 'hands the arguments to the import, defaulting to a checked, converted, non-overwriting preview' do
      allow(import).to receive(:call).with(confirm: false).and_return(status: 'preview', file_name: 'foto.png')

      expect(run(operation: 'upload', url: source)).to eq('status' => 'preview', 'file_name' => 'foto.png')
      expect(ImageImportService).to have_received(:new)
        .with(url: source, path: nil, overwrite: false, convert_to_webp: true)
    end

    it 'passes path, overwrite, convert_to_webp and confirm through' do
      allow(import).to receive(:call).with(confirm: true).and_return(status: 'saved', url: "#{bucket}/x.png")

      run(operation: 'upload', url: source, path: 'x.png', overwrite: true, convert_to_webp: false, confirm: true)

      expect(ImageImportService).to have_received(:new)
        .with(url: source, path: 'x.png', overwrite: true, convert_to_webp: false)
    end

    it 'drops the staging copy once a file put through upload_slot is stored, and only then' do
      staged = "#{bucket}/incoming/abc-123/portada.png?X-Amz-Signature=null-get"
      allow(import).to receive(:call).and_return({ status: 'preview' }, { status: 'saved' })

      run(operation: 'upload', url: staged)
      expect(FileStoreService.current).not_to have_received(:delete)

      run(operation: 'upload', url: staged, confirm: true)
      expect(FileStoreService.current).to have_received(:delete).with('incoming/abc-123/portada.png')
    end

    it 'deletes nothing after storing an image fetched from anywhere else' do
      allow(import).to receive(:call).and_return(status: 'saved')

      run(operation: 'upload', url: source, confirm: true)

      expect(FileStoreService.current).not_to have_received(:delete)
    end

    it 'passes an error from the import back as it came' do
      allow(import).to receive(:call).and_return(status: 'error', errors: ['does not look like an image'])

      expect(run(operation: 'upload', url: source)).to eq('status' => 'error',
                                                          'errors' => ['does not look like an image'])
    end

    it 'needs a url' do
      expect(run(operation: 'upload')['errors'].join).to include('url is required')
      expect(ImageImportService).not_to have_received(:new)
    end
  end

  describe 'operation=upload_slot' do
    before { FileStoreService.create_null }

    it 'answers where to PUT the file and the upload call that takes it from there' do
      result = run(operation: 'upload_slot', path: 'fotos/portada.png')

      expect(result).to include('status' => 'ready', 'expires_in_minutes' => 15)
      expect(result['put_url']).to match(%r{\A#{bucket}/incoming/[\w-]+/portada\.png\?.*put\z})
      expect(result['upload_with']).to eq("curl -sS --fail -T <local file> '#{result['put_url']}'")
      expect(result['then']).to include('operation' => 'upload', 'path' => 'portada.png')
      expect(result['then']['url']).to match(%r{\A#{bucket}/incoming/[\w-]+/portada\.png\?.*get\z})
    end

    it 'needs the name of the file' do
      expect(run(operation: 'upload_slot')['errors'].join).to include('path is required')
    end
  end

  it 'names the operations it knows when given another, without calling a private method' do
    result = run(operation: 'drop_staging_copy', url: "#{bucket}/incoming/x/y.png")

    expect(result['errors'].join).to include('list', 'find_usage', 'upload', 'upload_slot')
  end

  context 'as a user who may only read' do
    let(:user) { FactoryBot.create(:comercial) }

    before { FileStoreService.create_null }

    it 'lists and finds usage but cannot upload' do
      allow(ImageImportService).to receive(:new)

      expect(run['returned']).to eq(1)
      expect(run(operation: 'find_usage', image: 'x.png')['used']).to be false
      expect(run(operation: 'upload', url: 'https://images.example.com/x.gif')['errors'].first)
        .to include('Unauthorized')
      expect(run(operation: 'upload_slot', path: 'x.png')['errors'].first).to include('Unauthorized')
      expect(ImageImportService).not_to have_received(:new)
    end
  end
end
