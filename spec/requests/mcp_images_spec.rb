# frozen_string_literal: true

require 'rails_helper'

# Image tools over MCP: finding what is stored, where it is used, and pulling a
# new one in from a public URL.
RSpec.describe 'MCP image tools', type: :request do
  let(:user) { create(:administrator) }
  let(:oauth_application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end
  let(:headers) do
    token = Doorkeeper::AccessToken.create!(application: oauth_application, resource_owner_id: user.id,
                                            scopes: 'mcp', expires_in: 2.hours, use_refresh_token: true)
    { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_AUTHORIZATION' => "Bearer #{token.plaintext_token}" }
  end

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  describe 'list_images' do
    before do
      FileStoreService.create_null(files: [
                                     { key: 'demo-animado.gif', size: 2_048_000,
                                       last_modified: Time.zone.parse('2026-08-20') },
                                     { key: 'portada.webp', size: 40_960,
                                       last_modified: Time.zone.parse('2026-08-25') },
                                     { key: 'viejo-logo.png', size: 5_120,
                                       last_modified: Time.zone.parse('2026-01-05') }
                                   ])
    end

    it 'lists everything newest first, with public URLs and sizes' do
      result = call_tool('images')

      expect(result['returned']).to eq(3)
      expect(result['images'].pluck('name')).to eq(%w[portada.webp demo-animado.gif viejo-logo.png])
      expect(result['images'].first['url']).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/portada.webp')
      expect(result['images'].first['size_kb']).to eq(40.0)
    end

    it 'filters by extension, name and minimum size' do
      expect(call_tool('images',
                       { operation: 'list', extension: 'gif' })['images'].pluck('name')).to eq(['demo-animado.gif'])
      expect(call_tool('images',
                       { operation: 'list', query: 'logo' })['images'].pluck('name')).to eq(['viejo-logo.png'])
      expect(call_tool('images',
                       { operation: 'list', min_size_kb: 100 })['images'].pluck('name')).to eq(['demo-animado.gif'])
    end
  end

  describe 'find_image_usage' do
    let(:url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/demo-animado.gif' }

    it 'finds an article that mentions the image in its body, by name or by URL' do
      create(:article, title: 'Con gif', body: "Mirá esto: ![demo](#{url}) y seguimos.")
      create(:article, title: 'Sin gif', body: 'Nada de imágenes acá.')

      result = call_tool('images', { operation: 'find_usage', image: url })

      expect(result['used']).to be(true)
      expect(result['usage'].to_s).to include('Con gif').or include('article')
      expect(call_tool('images', { operation: 'find_usage', image: 'demo-animado.gif' })['image']).to eq(url)
    end

    it 'says so when nobody uses it' do
      expect(call_tool('images', { operation: 'find_usage', image: 'huerfana.png' })['used']).to be(false)
    end
  end

  describe 'upload_image_from_url' do
    let(:source) { 'https://images.example.com/animado.gif' }

    before do
      # The null store answers exists? => true for anything not named here
      FileStoreService.create_null(exists: { 'animado.gif' => false, 'animado.png' => false,
                                             'demo del producto.gif' => false, 'ya-esta.gif' => true })
      allow(Resolv).to receive(:getaddresses).and_call_original
      allow(Resolv).to receive(:getaddresses).with('images.example.com').and_return(['93.184.216.34'])
      stub_request(:get, source).to_return(body: "GIF89a\x01\x00\x01\x00 bytes",
                                           headers: { 'Content-Type' => 'application/octet-stream' })
    end

    it 'checks the image without storing it, then stores it on confirm' do
      result = call_tool('images', { operation: 'upload', url: source })
      expect(result['status']).to eq('preview')
      expect(result).to include('file_name' => 'animado.gif', 'content_type' => 'image/gif')
      expect(result['warnings'].join).to include('no WebP conversion')

      result = call_tool('images', { operation: 'upload', url: source, confirm: true })
      expect(result['status']).to eq('saved')
      expect(result['url']).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/animado.gif')
    end

    context 'with a PNG' do
      let(:source) { 'https://images.example.com/foto.png' }
      let(:png_bytes) do
        Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5' \
                        'ErkJggg==')
      end

      before do
        FileStoreService.create_null(exists: { 'foto.png' => false, 'foto.webp' => false })
        stub_request(:get, source).to_return(body: png_bytes, headers: { 'Content-Type' => 'image/png' })
        allow(FileStoreService.current).to receive(:upload).and_call_original
      end

      it 'stores the original and a WebP twin, and says so beforehand' do
        preview = call_tool('images', { operation: 'upload', url: source })
        expect(preview['also_stores']).to eq 'foto.webp'

        result = call_tool('images', { operation: 'upload', url: source, confirm: true })

        expect(result['status']).to eq('saved')
        expect(result['webp_url']).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/foto.webp')
        expect(FileStoreService.current).to have_received(:upload).with(anything, 'foto.png', 'image')
        expect(FileStoreService.current).to have_received(:upload).with(anything, 'foto.webp', 'image')
      end

      it 'stores only the original when told not to convert' do
        result = call_tool('images',
                           { operation: 'upload', url: source, convert_to_webp: false, confirm: true })

        expect(result).not_to have_key('webp_url')
        expect(FileStoreService.current).not_to have_received(:upload).with(anything, 'foto.webp', 'image')
      end

      it 'keeps the original and says so when the conversion fails' do
        allow(ImageConversionService).to receive(:convert_to_webp).and_raise('WebP conversion failed: no magick')

        result = call_tool('images', { operation: 'upload', url: source, confirm: true })

        expect(result['status']).to eq('saved')
        expect(result['warnings'].join).to include('no magick')
        expect(FileStoreService.current).to have_received(:upload).with(anything, 'foto.png', 'image')
      end
    end

    it 'takes the stored name from path when given' do
      result = call_tool('images', { operation: 'upload', url: source, path: 'blog/demo del producto' })
      expect(result['file_name']).to eq('demo del producto.gif')
    end

    it 'refuses to replace an existing name unless told to' do
      result = call_tool('images', { operation: 'upload', url: source, path: 'ya-esta.gif' })
      expect(result['status']).to eq('error')
      expect(result['errors'].join).to include('already exists')

      result = call_tool('images', { operation: 'upload', url: source, path: 'ya-esta.gif', overwrite: true })
      expect(result['status']).to eq('preview')
      expect(result['warnings'].join).to include('would be replaced')
    end

    it 'trusts the bytes, not the header: a page claiming to be a GIF is refused' do
      stub_request(:get, source).to_return(body: '<html>Not a GIF at all</html>',
                                           headers: { 'Content-Type' => 'image/gif' })
      expect(call_tool('images', { operation: 'upload', url: source })['errors'].join)
        .to include('does not look like an image')
    end

    it 'accepts a real image served as application/octet-stream, as a bucket does' do
      png = "\x89PNG\r\n\x1A\n".b + ('x' * 40)
      stub_request(:get, source).to_return(body: png, headers: { 'Content-Type' => 'application/octet-stream' })

      result = call_tool('images', { operation: 'upload', url: source, path: 'animado' })
      expect(result['content_type']).to eq('image/png')
      expect(result['file_name']).to eq('animado.png')
    end

    it 'refuses a host only the server can reach' do
      result = call_tool('images', { operation: 'upload', url: 'http://localhost:3000/secreto.gif' })
      expect(result['errors'].join).to include('not a public host')
    end
  end

  describe 'permissions' do
    let(:user) { create(:comercial) }

    it 'lets a read-only role list images but not upload one' do
      FileStoreService.create_null
      expect(call_tool('images')['returned']).to eq(1)
      expect(call_tool('images', { operation: 'upload', url: 'https://images.example.com/x.gif' }).to_s)
        .to include('Unauthorized')
    end
  end
end
