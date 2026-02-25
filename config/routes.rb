# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :services
  resources :service_areas
  ActiveAdmin.routes(self)

  # Custom admin routes
  namespace :admin do
    get 'current_user_roles', to: 'current_user#roles'
  end

  get 'images/filter/:bucket' => 'images#index'
  get 'images' => 'images#index'
  get 'images/new'
  post 'images/create'
  get 'images/show'
  get 'images/edit'
  put 'images/update'

  get '/webhooks' => 'web_hooks#index'
  post '/webhooks' => 'web_hooks#post'

  resources :logs, only: %i[index show]
  resources :articles,
            :resources,
            :news,
            :coupons

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
  end

  get 'api/events' => 'home#index'
  get 'api/trainers' => 'home#trainers'
  get 'api/kleerers' => 'home#kleerers'
  get 'api/community_events' => 'home#index_community' # TODO: should deprecate (used in website?)
  get 'api/events/:id' => 'home#show' # TODO: should deprecate (used in website?)
  get 'api/events/event_types/:id' => 'home#event_by_event_type' # TODO: should deprecate (used in website?)
  get 'api/categories' => 'home#categories'
  get 'api/catalog' => 'home#catalog'


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  # root to: 'dashboard#index'
  root to: 'admin/dashboard#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  resources :settings

  resources :categories

  resources :event_types do
    get 'certificate_preview', on: :member
    get 'participants', on: :member
  end
  get 'event_types/:id/testimonies', to: 'event_types#testimonies'
  get 'event_types/filter/:lang/active/:active/dur/:duration/ic/:indexcanonical' => 'event_types#index'
  get 'event_types/:id/events' => 'event_types#events'

  resources :trainers

  get 'events/filter/:country_iso' => 'events#index'

  get 'events/:id/send_certificate' => 'events#send_certificate'
  post 'events/:id/send_certificate_with_hr' => 'events#send_certificate_with_hr'

  get 'events/:event_id/participant_confirmed' => 'participants#confirm'
  get 'events/:event_id/participants/:id/certificate' => 'participants#certificate'
  get 'events/:event_id/participants_print' => 'participants#print'
  get 'events/:event_id/participants_survey' => 'participants#survey'
  post 'events/:event_id/participants_batch_load' => 'participants#batch_load'
  resources :events do
    resources :participants do
      post 'copy', on: :member
    end
    get 'copy', on: :member
  end
  patch 'events/:id/edit' => 'events#update'

  resources :roles

  devise_for :users
  resources :users

  get 'dashboard' => 'dashboard#index'
  get 'dashboard/pricing' => 'dashboard#pricing'
  get 'dashboard/past_events' => 'dashboard#past_events'
  get 'dashboard/countdown' => 'dashboard#countdown'
  get 'dashboard/funneling' => 'dashboard#funneling'
  get 'dashboard/:country_iso' => 'dashboard#index'
  get 'dashboard/pricing/:country_iso' => 'dashboard#pricing'

  get 'events/update_trainer_select/:id' => 'ajax#events_update_trainer_select'
  get 'events/update_trainer2_select/:id' => 'ajax#events_update_trainer2_select'
  get 'events/update_trainer3_select/:id' => 'ajax#events_update_trainer3_select'
  get 'events/load_cancellation_policy/:id' => 'ajax#load_cancellation_policy'

  get 'participants/search' => 'participants#search'
  get 'participants/followup' => 'participants#followup'
  get 'oauth_tokens/' => 'oauth_tokens#index'
  get 'oauth_tokens/new' => 'oauth_tokens#new'
  get 'oauth_tokens/callback' => 'oauth_tokens#callback'

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
