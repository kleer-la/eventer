Eventer::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root :to => 'dashboard#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  resources :settings

  resources :categories

  resources :event_types

  resources :trainers

  resources :events do
    resources :participants
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
  get 'dashboard/ratings' => 'dashboard#ratings' 
  get 'dashboard/calculate_rating' => 'dashboard#calculate_rating'
  get 'dashboard/:country_iso' => 'dashboard#index'
  get 'dashboard/pricing/:country_iso' => 'dashboard#pricing'    

  get 'api/events' => 'home#index'
  get 'api/trainers' => 'home#trainers'
  get 'api/kleerers' => 'home#kleerers'
  get 'api/community_events' => 'home#index_community'
  get 'api/events/:id' => 'home#show'
  get 'api/events/event_types/:id' => 'home#event_by_event_type'
  get 'api/event_types' => 'home#event_type_index'
  get 'api/event_types/:id' => 'home#event_type_show'
  get 'api/event_types/:id/trainers' => 'home#show_event_type_trainers'
  get 'api/categories' => 'home#categories'

  get 'api/2/upcoming_events' => 'api#index'
  get 'api/2/participants/synch' => 'api#participants_synch'


  get 'public_events/:id' => 'public_events#show'
  get 'public_events/:event_id/watch' => 'public_events#watch'
  get 'public_events/:event_id/watch/:participant_id' => 'public_events#watch'

  get 'events/update_trainer_select/:id' => 'ajax#events_update_trainer_select'
  get 'events/update_trainer2_select/:id' => 'ajax#events_update_trainer2_select'
  get 'events/update_trainer3_select/:id' => 'ajax#events_update_trainer3_select'
  get 'events/load_cancellation_policy/:id' => 'ajax#load_cancellation_policy'

  get 'events/filter/:country_iso' => 'events#index'

  get 'events/:id/start_webinar' => 'events#start_webinar'
  get 'events/:id/broadcast_webinar' => 'events#broadcast_webinar'
  get 'events/:id/push_to_crm' => 'events#push_to_crm'
  get 'events/:id/send_certificate' => 'events#send_certificate'

  get 'events/:event_id/participant_confirmed' => 'participants#confirm'
  post 'events/payuco/confirmation' =>'participants#payuco_confirmation'
  get 'events/payuco/response' =>'participants#payuco_response'
  get 'events/:event_id/participants/:id/certificate' => 'participants#certificate'
  get 'events/:event_id/participants_print' => 'participants#print'
  get 'events/:event_id/participants_survey' => 'participants#survey'
  post 'events/:event_id/participants_batch_load' => 'participants#batch_load'

  get 'participants/search' => 'participants#search'

  get "marketing" => 'marketing#index'
  get "marketing/:time_segment" => 'marketing#index'
  get "marketing/campaigns/:id" => 'marketing#campaign'
  get "marketing/campaigns/:id/:time_segment" => 'marketing#campaign'
  get 'events/:id/viewed' => 'marketing#viewed'
  #   resources :products

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
