# CLAUDE.md

KEventer is the backend for Kleer's public website (kleer.la, served by the
separate `website17` repo): courses, calendars, registrations, content (articles,
resources, services, podcasts, news, pages) and an MCP server that lets people
edit that content from Claude. Rails 8.1, Ruby 3.4.7.

## Where commands run

Claude Code runs on the **host**, which has no Ruby. Every Rails, bundle, rake,
rubocop, brakeman and `bin/deploy` command goes through the devcontainer, which
mounts this repo at `/app`:

```bash
docker exec eventer_devcontainer-app-1 bundle exec rake ci
docker exec eventer_devcontainer-app-1 bundle exec rspec spec/models/event_spec.rb
docker exec eventer_devcontainer-app-1 bundle exec rubocop
docker exec eventer_devcontainer-app-1 bundle exec brakeman
docker exec eventer_devcontainer-app-1 bin/rails db:migrate
```

File operations (read, edit, git) happen on the host as usual. If the container
is stopped: `docker start eventer_devcontainer-app-1`.

Databases: SQLite in development and test, PostgreSQL in QA and production — so
don't rely on Postgres-only SQL passing locally. Environment variables come from
`eventer.env` (template: `eventer.env.template`).

## Testing

- `rake ci` is what GitHub Actions runs (`.github/workflows/ci.yml`) and what
  "the full CI" means when landing work. It runs RSpec excluding `slow`-tagged
  specs. `rake slow_tests` runs only those (`slow: true`, 3 examples that hit
  real S3 / webhooks); CI does not run them.
- RSpec only; Cucumber was retired (Jun 2026). Browser coverage is system specs:
  `driven_by(:selenium, using: :headless_chrome)` for JS, `:rack_test` otherwise.
- **A new headless-Chrome system spec must call `ENV.delete('LD_PRELOAD')` before
  `driven_by`.** The devcontainer preloads jemalloc for Rails; Chrome inherits it
  and dies, and Selenium misreports that as `InvalidSessionIdError`. See
  `spec/system/admin/event_pricing_visibility_spec.rb`.
- Controller specs don't render views unless they use `render_views`, so an
  ActionText `body.to_s` comes back `""` there.
- Work test-first and outside-in: start from a request or system spec for the
  behavior, then go down to model specs. Prefer the smallest increment that can
  be verified end to end.

## Architecture map

The domain is conventional Rails; read the models for detail. Pointers to what
isn't obvious from file names:

- **Events**: `Event` (a dated session, with early-bird / volume / coupon
  pricing and up to three trainers) is an instance of `EventType` (the course
  definition, multi-language, `platform` enum keventer/academia). `Participant`
  moves New → Contacted → Confirmed → Attended → Certified and carries payment,
  rating and certificate data.
- **Content**: `Article`, `Resource`, `Service` / `ServiceArea`, `Podcast` /
  `Episode`, `News`, `Page`. Content is Spanish/English via `lang` fields or
  separate records. The `Recommendable` concern links EventTypes, Articles,
  Resources and Services; `ImageReference` tracks where images are used.
- **Admin**: ActiveAdmin (`app/admin`), Devise auth, CanCanCan `Ability`.
- **Public API**: `app/controllers/api` (`v3` is the current namespace) — this
  is what website17 consumes. Changing a response shape can break the site.
- **MCP server**: `fast-mcp` tools in `app/tools` (one tool per entity with an
  `operation` argument, not one tool per verb), authenticated with OAuth via
  Doorkeeper. Specs in `spec/tools`.
- **Integrations**: S3 for files (`kleer-images` bucket is in `sa-east-1`), Xero
  for invoicing, reCAPTCHA shared with website17 (the secret here must match the
  site key there).

## Deployment

Kamal on a Hetzner server (`5.78.92.152`) — not Heroku, which the project left.
`bin/deploy` wraps `bundle exec kamal`: it sources `eventer.env` and strips the
devcontainer `credsStore` that would otherwise fail `docker login`. Run it
through the container:

```bash
docker exec eventer_devcontainer-app-1 bin/deploy config -d qa   # check :version:
docker exec eventer_devcontainer-app-1 bin/deploy deploy -d qa   # QA → qa.eventos.kleer.la
docker exec eventer_devcontainer-app-1 bin/deploy deploy         # production → eventos.kleer.la
docker exec eventer_devcontainer-app-1 bin/deploy app logs -f -d qa
```

Deploy QA first and verify it (`curl https://qa.eventos.kleer.la/up` → 200, plus
checking the actual change) before production. A production deploy needs an
explicit request from the user each time.

Each destination runs a `web` role and a `job` role (`rake jobs:work`) on the
same server and builds the image remotely over SSH. QA takes its database from
`DATABASE_URL_QA`; destinations are configured in `config/deploy.yml` +
`config/deploy.qa.yml`, secrets in `.kamal/secrets` + `.kamal/secrets.qa`.
