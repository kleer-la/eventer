# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  ActiveAdmin.routes(self)

  # Custom admin routes
  namespace :admin do
    get 'current_user_roles', to: 'current_user#roles'
    get 'google_oauth/authorize', to: 'google_oauth#authorize', as: :google_oauth_authorize
    get 'google_oauth/callback', to: 'google_oauth#callback', as: :google_oauth_callback
  end

  get '/webhooks' => 'web_hooks#index'
  post '/webhooks' => 'web_hooks#post'

  namespace :api do
    namespace :v3 do
      post 'participants/interest'
      post 'events/:event_id/participants/register', to: 'participants#register'
      get 'events/:event_id/participants/pricing_info', to: 'participants#pricing_info'
      resources :podcasts, only: [:index]
    end
    resources :service_areas, only: %i[index show] do
      get :preview, on: :member
      collection do
        get 'programs', to: 'service_areas#programs'
      end
    end
    resources :articles, only: %i[index show]
    resources :resources, only: %i[index show] do
      collection do
        get :preview
      end
    end
    resources :pages, only: %i[show]
    resources :contacts, only: %i[create show] do
      get ':contact_id/status', on: :collection, to: 'contacts#status'
      post :contact_us, on: :collection
    end
    post 'contact_us', to: 'contacts#contact_us' # TODO: remove, duplicated with api/contacts/contact_us

    resources :assessments, only: [:show]
    resources :news, only: [:index] do
      collection do
        get :preview
      end
    end
    get 'event_types', to: 'event_types#index'
    get 'event_types/:id' => 'event_types#show'
    get 'event_types/:id/testimonies' => 'event_types#show_event_type_testimonies'
    resources :short_urls, only: [:show], param: :short_code
    resources :events, only: [:show]

    # Consultant booking endpoints
    get 'service_areas/:slug/consultants', to: 'consultants#index'
    get 'consultants/:id/availability', to: 'consultants#availability'
    post 'consultants/:id/bookings', to: 'consultants#create_booking'
  end

  get 'api/events' => 'home#index'
  get 'api/trainers' => 'home#trainers'
  get 'api/kleerers' => 'home#kleerers'
  get 'api/community_events' => 'home#index_community'
  get 'api/events/:id' => 'home#show'
  get 'api/events/event_types/:id' => 'home#event_by_event_type'
  get 'api/categories' => 'home#categories'
  get 'api/catalog' => 'home#catalog'

  root to: 'admin/dashboard#index'

  # Participant registration and certificates (public-facing)
  get 'events/:event_id/participant_confirmed' => 'participants#confirm'
  get 'events/:event_id/participants/:id/certificate' => 'participants#certificate'
  post 'events/:event_id/participants_batch_load' => 'participants#batch_load'
  resources :events, only: [] do
    resources :participants, only: %i[new create edit update]
  end

  devise_for :users

  # Xero OAuth
  get 'oauth_tokens/new' => 'oauth_tokens#new'
  get 'oauth_tokens/callback' => 'oauth_tokens#callback'
end
