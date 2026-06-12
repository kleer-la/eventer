# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateArticleAudioJob, type: :job do
  let(:article) { create(:article, lang: 'es', body: 'Hola **mundo**, esto es un articulo.') }
  let(:store_service) { instance_double(FileStoreService) }
  let(:ok_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }

  before do
    allow(FileStoreService).to receive(:current).and_return(store_service)
    allow(store_service).to receive(:upload).and_return('https://kleer-images.s3.sa-east-1.amazonaws.com/article.mp3')
    # Pretend edge-tts ran: write a non-empty file at the --write-media path it was given.
    allow(Open3).to receive(:capture3) do |*args|
      media = args[args.index('--write-media') + 1]
      File.binwrite(media, 'FAKE-MP3-BYTES')
      ['', '', ok_status]
    end
  end

  describe '#perform' do
    it 'invokes edge-tts with the Spanish voice and the article text file' do
      GenerateArticleAudioJob.perform_now(article.id)
      expect(Open3).to have_received(:capture3).with(
        'edge-tts', '--voice', 'es-CO-SalomeNeural', '--file', anything, '--write-media', anything
      )
    end

    it 'uploads the mp3 and stores the url on the article audio column' do
      GenerateArticleAudioJob.perform_now(article.id)
      expect(store_service).to have_received(:upload).with(anything, "article_#{article.id}.mp3", 'image')
      expect(article.reload.audio).to eq('https://kleer-images.s3.sa-east-1.amazonaws.com/article.mp3')
    end

    it 'uses the English voice for English articles' do
      en_article = create(:article, lang: 'en', body: 'Hello world, this is an article.')
      GenerateArticleAudioJob.perform_now(en_article.id)
      expect(Open3).to have_received(:capture3).with(
        'edge-tts', '--voice', 'en-US-JennyNeural', '--file', anything, '--write-media', anything
      )
    end

    it 'honours a voice override from the environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TTS_VOICE_ES').and_return('es-AR-ElenaNeural')
      GenerateArticleAudioJob.perform_now(article.id)
      expect(Open3).to have_received(:capture3).with(
        'edge-tts', '--voice', 'es-AR-ElenaNeural', '--file', anything, '--write-media', anything
      )
    end

    it 'does nothing when the body is blank' do
      blank = build(:article, body: '')
      blank.save(validate: false)
      GenerateArticleAudioJob.perform_now(blank.id)
      expect(store_service).not_to have_received(:upload)
      expect(blank.reload.audio).to be_nil
    end

    context 'when edge-tts fails' do
      let(:fail_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      before { allow(Open3).to receive(:capture3).and_return(['', 'boom', fail_status]) }

      it 'logs the error, raises and does not set the audio url' do
        expect(Log).to receive(:log).with(:app, :error, anything, anything)
        expect { GenerateArticleAudioJob.perform_now(article.id) }.to raise_error(/edge-tts failed/)
        expect(article.reload.audio).to be_nil
      end
    end
  end
end
