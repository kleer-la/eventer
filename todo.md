# Task as of ago 12

## Rules
- delete test rule button (not implemented)

## Improve News
- explain meaning of fields. I.e. url: more info / image: to show in the news page
- do we need to add an audio field?
- move visible as 2nd field in the show/edit form
- make visible default to false
- website17: buttons for audio / video / external site (akin of podcast card)

## Improve Assessment
- header/footer image
- Show only Question / anwser
- change color palette to teal/dark green

# Migración a ActiveAdmin

## Remove unused event_type visibility functionallity
- review public_event functionallity, do we want to keep it?
  - Remove Event model scopes: public_events, public_commercial, public_community_events, public_commercial_visible, public_community_visible, public_and_visible, public_and_past_visible, public_courses
  - Remove visibility_type field from Event model and database
  - Update controllers: home_controller.rb, participants_controller.rb, dashboard_controller.rb, api/event_types_controller.rb
  - Update admin/events.rb - remove visibility_type from forms and displays
  - Remove visibility_type from views: events/_form.html.haml, events/index.html.haml, events/show.html.haml, event_types/events.html.haml
  - Update tests: event_spec.rb, factories.rb, cucumber steps
  - Remove translations for visibility_type from locale files
  - Create migration to remove visibility_type column

## Participantes
- ~~participant copy -> qty <-1~~ ✓
- ~~send_certificate (moverlo a ActiveAdmin)~~ ✓
- ~~ver certificate  (moverlo a ActiveAdmin)~~ ✓
- ~~download certificate  (moverlo a ActiveAdmin)~~ ✓
- ~~agregar nuevos participantes en batch~~ ✓
- best in place
- ~~link desde dashboard a event/view~~ ✓

## Event
- ~~lógica fechas~~ ✓
- ~~lógica OL~~ ✓
- ~~lógica trainers~~ ✓
- ~~logica precios~~ ✓
- ~~logica visibilidad~~ ✓
- ~~carga dinámica de trainers x tipo evento~~ ✓
- ~~carga dinámica de política de cancelación x tipo evento~~ ✓

## event Type
- ~~Preview certificados (index action) - fixed admin route~~ ✓
- ~~List of events (index action) - fixed admin route and filter parameter~~ ✓
- ~~List of testimonies (index action) - fixed admin route and filter parameter~~ ✓
- ~~List of participants (index action) - fixed admin route~~ ✓

## Participants
- ~~use status color from model~~ ✓

# Gral
- ~~Revisar ActiveAdmin actuales para evitar N+1 queries:~~ ✓
  - ~~app/admin/categories.rb (clean)~~ ✓
  - ~~app/admin/logs.rb (clean)~~ ✓
  - ~~app/admin/roles.rb (clean)~~ ✓
  - ~~app/admin/settings.rb (clean)~~ ✓
  - ~~app/admin/testimonies.rb (fixed: :service in index)~~ ✓
  - ~~app/admin/users.rb (fixed: :roles in index)~~ ✓
  - ~~app/admin/podcasts.rb (fixed: :episodes in show)~~ ✓
  - ~~app/admin/episodes.rb (fixed: :podcast in index)~~ ✓
  - ~~app/admin/coupons.rb (fixed: :event_types in show)~~ ✓
  - ~~app/admin/services.rb (fixed: :service_area in index)~~ ✓
  - ~~app/admin/news.rb (fixed: :trainers in show)~~ ✓
  - ~~app/admin/oauth_tokens.rb (clean)~~ ✓
  - ~~app/admin/mail_templates.rb (clean)~~ ✓
  - ~~app/admin/trainers.rb (fixed: :country, :event_types, :articles, :authorships, :translators, :news in show)~~ ✓
  - ~~app/admin/articles.rb (fixed: :category, :trainers in index/show)~~ ✓
  - ~~app/admin/resource.rb (fixed: :category, :authors, :translators, :illustrators in index/show)~~ ✓
  - ~~app/admin/service_area.rb (fixed: :services, :testimonies in show)~~ ✓
  - ~~app/admin/pages.rb (fixed: :sections in show)~~ ✓
  - ~~app/admin/short_urls.rb (clean)~~ ✓
  - ~~app/admin/webhooks.rb (clean)~~ ✓
  - ~~app/admin/recommended_content.rb (already optimized: :source, :target)~~ ✓
  - ~~app/admin/assessments.rb (fixed: :resource, :question_groups, :questions, :rules in index/show)~~ ✓
  - ~~app/admin/rules.rb (fixed: :assessment, pre-loaded questions in show)~~ ✓
  - ~~app/admin/contacts.rb (fixed: :assessment, responses: [:question, :answer] in index/show)~~ ✓
  - ~~app/admin/events.rb (clean - already optimized)~~ ✓
  - ~~app/admin/event_types.rb (fixed: :trainers, :categories, :canonical, recommended_contents: :target in index/show)~~ ✓
  - ~~app/admin/participants.rb (clean - already optimized)~~ ✓
  - ~~app/admin/dashboard.rb (fixed: :event_type, :trainers in grouped_events and pricing_events)~~ ✓
  - ~~app/admin/images.rb (clean - register_page, no ActiveRecord queries)~~ ✓

## imagenes
- ~~mostrar pdf en vez de bajarlos~~ ✓
- ~~borrar imágenes~~ ✓
- ~~Limpiar nombre~~ ✓

# Task as of ago 12
- ~~Bug: Area Filter in Log doesn't work (fixed enum filter collections)~~ ✓

## News
- ~~backend: visible flag (db / admin / api) - completed~~ ✓
- ~~frontend: dont show non visible in normal view - API updated, frontend will automatically hide~~ ✓
- ~~add a preview: show all news - /api/news/preview endpoint added~~ ✓
- ~~preview: new look (one new per line / modern cards, like podcast)~~ ✓

## Assessent
- ~~backend Assessment view: show answers one in each line and with position at the start of the line~~ ✓
- ~~frontend Questions: show ordered by position - implemented at model level (backend)~~ ✓
- ~~frontend Answers: show ordered by position - implemented at model level (backend)~~ ✓
- ~~frontend Question, answers text: convert from markdown to html~~ ✓
- ~~backend report generation: render markdown in HTML and PDF reports~~ ✓
- pdf report has date in English for a Spanish report

## webhook
- ~~add responsable (trainer, mandatory) - add it to the index view~~ ✓
- ~~add comment (text)~~ ✓

# Ideas
- Category index: visible tag edition in place, could it be replicateded in participants?
- ~~remove participants_synch~~ ✓

## Website17
- Clean up: make layout default
