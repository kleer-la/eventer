# Migración a ActiveAdmin

##Participantes
X participant copy -> qty <-1
X send_certificate (moverlo a ActiveAdmin)
X ver certificate  (moverlo a ActiveAdmin)
X download certificate  (moverlo a ActiveAdmin)
X agregar nuevos participantes en batch
- best in place
X link desde dashboard a event/view

## Event
X lógica fechas
X lógica OL
X lógica trainers
X logica precios
X logica visibilidad
X carga dinámica de trainers x tipo evento
X carga dinámica de política de cancelación x tipo evento

## event Type
X Preview certificados (index action) - fixed admin route
X List of events (index action) - fixed admin route and filter parameter
X List of testimonies (index action) - fixed admin route and filter parameter
X List of participants (index action) - fixed admin route

## Participants
X use status color from model

# Gral
X Revisar ActiveAdmin actuales para evitar N+1 queries:
  X app/admin/categories.rb (clean)
  X app/admin/logs.rb (clean)
  X app/admin/roles.rb (clean)
  X app/admin/settings.rb (clean)
  X app/admin/testimonies.rb (fixed: :service in index)
  X app/admin/users.rb (fixed: :roles in index)
  X app/admin/podcasts.rb (fixed: :episodes in show)
  X app/admin/episodes.rb (fixed: :podcast in index)
  X app/admin/coupons.rb (fixed: :event_types in show)
  X app/admin/services.rb (fixed: :service_area in index)
  X app/admin/news.rb (fixed: :trainers in show)
  X app/admin/oauth_tokens.rb (clean)
  X app/admin/mail_templates.rb (clean)
  X app/admin/trainers.rb (fixed: :country, :event_types, :articles, :authorships, :translators, :news in show)
  X app/admin/articles.rb (fixed: :category, :trainers in index/show)
  X app/admin/resource.rb (fixed: :category, :authors, :translators, :illustrators in index/show)
  X app/admin/service_area.rb (fixed: :services, :testimonies in show)
  X app/admin/pages.rb (fixed: :sections in show)
  X app/admin/short_urls.rb (clean)
  X app/admin/webhooks.rb (clean)
  X app/admin/recommended_content.rb (already optimized: :source, :target)
  X app/admin/assessments.rb (fixed: :resource, :question_groups, :questions, :rules in index/show)
  X app/admin/rules.rb (fixed: :assessment, pre-loaded questions in show)
  X app/admin/contacts.rb (fixed: :assessment, responses: [:question, :answer] in index/show)
  X app/admin/events.rb (clean - already optimized)
  X app/admin/event_types.rb (fixed: :trainers, :categories, :canonical, recommended_contents: :target in index/show)
  X app/admin/participants.rb (clean - already optimized)
  X app/admin/dashboard.rb (fixed: :event_type, :trainers in grouped_events and pricing_events)
  X app/admin/images.rb (clean - register_page, no ActiveRecord queries)

## imagenes
X mostrar pdf en vez de bajarlos
X borrar imágenes
X Limpiar nombre

# Task as of ago 12
X Bug: Area Filter in Log doesn't work (fixed enum filter collections)

## News
X backend: visible flag (db / admin / api) - completed
X frontend: dont show non visible in normal view - API updated, frontend will automatically hide
X add a preview: show all news - /api/news/preview endpoint added
X preview: new look (one new per line / modern cards, like podcast)

## Assessent
X backend Assessment view: show answers one in each line and with position at the start of the line
X frontend Questions: show ordered by position - implemented at model level (backend)
X frontend Answers: show ordered by position - implemented at model level (backend)
- frontend Question, answers text: convert from markdown to html

## webhook
- add responsable (trainer, mandatory) - add it to the index view
- add comment (text)

## Rules
- delete test rule button (not implemented)

# Website17
## Clean up
- remove participants_synch

# Ideas
- Category index: visible tag edition in place, could it be replicateded in participants?