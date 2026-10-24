# Build stage
FROM ruby:4.0.9-slim AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      libmagickwand-7.q16-dev \
      libcurl4-openssl-dev \
      libyaml-dev \
      libjemalloc-dev \
      git \
      pkg-config \
      nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4

COPY . .

# Asset precompilation fails without a DB (ActiveAdmin loads models via routes).
# Assets compile at runtime via config.assets.compile = true in production.rb.
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production \
    DATABASE_URL="postgresql://dummy:dummy@localhost/dummy" \
    bundle exec rails assets:precompile || true

# Runtime stage
FROM ruby:4.0.9-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 \
      imagemagick \
      libcurl4 \
      libjemalloc2 \
      python3 \
      python3-pip \
      ffmpeg \
      nodejs && \
    rm -rf /var/lib/apt/lists/*

# imagemagick: mini_magick shells out to `magick`, so the library alone
# (libmagickwand) is not enough — without the binary every WebP conversion
# fails quietly, which is what happened after the move off Heroku.
# edge-tts: free, key-less text-to-speech CLI used by GenerateArticleAudioJob and
# TtsBriefingService. ffmpeg (ffmpeg + ffprobe) is TtsBriefingService's own: padding
# and concatenating beats into one MP3.
# Pinned: edge-tts talks to an undocumented Microsoft endpoint, and 7.2.8 got a 403 on
# the websocket handshake (QA, 2026-10-15) while the unpinned layer sat in the build cache.
# When it breaks again, bump the version here — that also busts the cache.
RUN pip3 install --no-cache-dir --break-system-packages edge-tts==7.3.1

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

WORKDIR /app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

RUN mkdir -p tmp/pids

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
