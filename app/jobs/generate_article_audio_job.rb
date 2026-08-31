# frozen_string_literal: true

require 'open3'

# Generates a spoken-audio (MP3) version of an article body using the edge-tts
# CLI (the same free, key-less engine used in jaomai), uploads it to S3 and
# stores the public URL on the article's `audio` column.
class GenerateArticleAudioJob < ActiveJob::Base
  include ApplicationHelper
  queue_as :default

  DEFAULT_VOICES = {
    'es' => 'es-CO-SalomeNeural',
    'en' => 'en-US-JennyNeural'
  }.freeze

  # Narration weighs around 300 bytes of MP3 per character of text. A tenth of
  # that is not a terse article, it is a truncated stream — see #verify_complete.
  MIN_BYTES_PER_CHAR = 30

  def perform(article_id)
    article = Article.find(article_id)
    return if article.body.blank?

    text = markdown_to_text(article.body)
    return if text.blank?

    generate_and_store(article, text)
  rescue StandardError => e
    Log.log(:app, :error, "Failed to generate audio for article #{article_id}",
            { error: e.message, backtrace: e.backtrace })
    raise e
  end

  private

  def generate_and_store(article, text)
    base = "article_#{article.id}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    txt_path = Rails.root.join('tmp', "#{base}.txt")
    mp3_path = Rails.root.join('tmp', "#{base}.mp3")

    File.write(txt_path, text)
    synthesize(voice_for(article.lang), txt_path, mp3_path, text.length)

    url = FileStoreService.current.upload(mp3_path, "article_#{article.id}.mp3", 'image')
    article.update_column(:audio, url)
    Log.log(:app, :info, "Audio generated for article #{article.id}", { audio: url })
  ensure
    File.delete(txt_path) if txt_path && File.exist?(txt_path)
    File.delete(mp3_path) if mp3_path && File.exist?(mp3_path)
  end

  # Convert markdown to HTML then strip HTML tags for plain narration text.
  def markdown_to_text(text)
    return '' if text.nil?

    html = markdown(text)
    ActionView::Base.full_sanitizer.sanitize(html).strip
  end

  def voice_for(lang)
    ENV["TTS_VOICE_#{lang.to_s.upcase}"].presence || DEFAULT_VOICES[lang] || DEFAULT_VOICES['en']
  end

  def synthesize(voice, txt_path, mp3_path, text_length)
    _stdout, stderr, status = Open3.capture3(
      'edge-tts', '--voice', voice, '--file', txt_path.to_s, '--write-media', mp3_path.to_s
    )
    raise "edge-tts failed (#{status.exitstatus}): #{stderr}" unless status.success?

    verify_complete(mp3_path, text_length)
  end

  # edge-tts can exit 0 having written only part of the stream. One article came
  # back as 27 KB for 5.700 characters — fourteen seconds of a nine-minute read —
  # and a check for "more than zero bytes" waved it through, so the site served
  # the stump for days. Measure the file against the text it came from instead,
  # and let the failure reach the retry rather than the reader.
  def verify_complete(mp3_path, text_length)
    raise 'edge-tts produced no audio' unless File.exist?(mp3_path) && File.size(mp3_path).positive?

    size = File.size(mp3_path)
    return if size >= text_length * MIN_BYTES_PER_CHAR

    raise "edge-tts wrote #{size} bytes for #{text_length} characters: the stream was cut short"
  end
end
