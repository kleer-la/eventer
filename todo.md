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
- Probar certificados
- ???

## Participants
X use status color from model

## Gral
- Revisar ActiveAdmin actuales para evitar N+1 queries:
  X app/admin/categories.rb (clean)
  X app/admin/logs.rb (clean)
  X app/admin/roles.rb (clean)
  X app/admin/settings.rb (clean)
  - app/admin/testimonies.rb (N+1: :service in index)
  - app/admin/users.rb (N+1: :roles in index)
  - app/admin/podcasts.rb (N+1: :episodes in show)
  - app/admin/episodes.rb (N+1: :podcast in index)
  - app/admin/coupons.rb (N+1: :event_types in show)
  - app/admin/services.rb (N+1: :service_area in index)
  - app/admin/news.rb
  - app/admin/oauth_tokens.rb
  - app/admin/mail_templates.rb
  - app/admin/trainers.rb
  - app/admin/articles.rb
  - app/admin/resource.rb
  - app/admin/service_area.rb
  - app/admin/pages.rb
  - app/admin/short_urls.rb
  - app/admin/webhooks.rb
  - app/admin/recommended_content.rb
  - app/admin/assessments.rb
  - app/admin/rules.rb
  - app/admin/contacts.rb
  - app/admin/events.rb
  - app/admin/event_types.rb
  - app/admin/participants.rb
  - app/admin/dashboard.rb
  - app/admin/images.rb

## imagenes
X mostrar pdf en vez de bajarlos
X borrar imágenes
? filtro
X Limpiar nombre

# Task as of ago 12
- Bug: Area Filter in Log doesn't work

## News
- backend: visible flag (db / admin / api)
- frontend: dont show non visible in normal view
- add a preview: show all news
- preview: new look (one new per line / modern cards, like podcast)

## Assessent
- backend Assessment view: show answers one in each line and with position at the start of the line
- frontend Questions: show ordered by position
- frontend Answers: show ordered by position
- frontend Question, answers text: convert from markdown to html

## webhook
- add responsable (trainer, mandatory) - add it to the index view
- add comment (text)
