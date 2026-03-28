# Build stage
FROM ruby:3.4.7-slim AS build

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
FROM ruby:3.4.7-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 \
      libmagickwand-7.q16-10 \
      libcurl4 \
      libjemalloc2 \
      nodejs && \
    rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

WORKDIR /app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

RUN mkdir -p tmp/pids

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
