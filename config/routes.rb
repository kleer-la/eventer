Eventer::Application.routes.draw do

  resources :settings


  resources :categories


  resources :event_types

  resources :trainers

  resources :events do
    resources :participants
  end

  resources :roles

  devise_for :users
  resources :users

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  match 'dashboard' => 'dashboard#index'
  match 'dashboard/pricing' => 'dashboard#pricing'
  match 'dashboard/past_events' => 'dashboard#past_events'
  match 'dashboard/countdown' => 'dashboard#countdown'
  match 'dashboard/funneling' => 'dashboard#funneling'
  match 'dashboard/ratings' => 'dashboard#ratings'
  match 'dashboard/calculate_rating' => 'dashboard#calculate_rating'
  match 'dashboard/:country_iso' => 'dashboard#index'
  match 'dashboard/pricing/:country_iso' => 'dashboard#pricing'

  match 'api/events' => 'home#index'
  match 'api/trainers' => 'home#trainers'
  match 'api/kleerers' => 'home#kleerers'
  match 'api/community_events' => 'home#index_community'
  match 'api/events/:id' => 'home#show'
  match 'api/event_types' => 'home#event_type_index'
  match 'api/event_types/:id' => 'home#event_type_show'
  match 'api/event_types/:id/trainers' => 'home#show_event_type_trainers'
  match 'api/categories' => 'home#categories'

  match 'api/2/upcoming_events' => 'api#index'
  match 'api/2/participants/synch' => 'api#participants_synch'


  match 'public_events/:id' => 'public_events#show'
  match 'public_events/:event_id/watch' => 'public_events#watch'
  match 'public_events/:event_id/watch/:participant_id' => 'public_events#watch'

  match 'events/update_trainer_select/:id' => 'ajax#events_update_trainer_select'
  match 'events/update_trainer2_select/:id' => 'ajax#events_update_trainer2_select'
  match 'events/update_trainer3_select/:id' => 'ajax#events_update_trainer3_select'
  match 'events/load_cancellation_policy/:id' => 'ajax#load_cancellation_policy'

  match 'events/filter/:country_iso' => 'events#index'

  match 'events/:id/start_webinar' => 'events#start_webinar'
  match 'events/:id/broadcast_webinar' => 'events#broadcast_webinar'
  match 'events/:id/push_to_crm' => 'events#push_to_crm'
  match 'events/:id/send_certificate' => 'events#send_certificate'

  match 'events/:event_id/participant_confirmed' => 'participants#confirm'
  post 'events/payuco_confirmation' =>'participantes#payuco_confirmation'
  match 'events/:event_id/participants/:id/certificate' => 'participants#certificate'
  match 'events/:event_id/participants_print' => 'participants#print'
  match 'events/:event_id/participants_survey' => 'participants#survey'
  match 'events/:event_id/participants_batch_load' => 'participants#batch_load'

  match 'participants/search' => 'participants#search'

  get "marketing" => 'marketing#index'
  get "marketing/:time_segment" => 'marketing#index'
  get "marketing/campaigns/:id" => 'marketing#campaign'
  get "marketing/campaigns/:id/:time_segment" => 'marketing#campaign'
  match 'events/:id/viewed' => 'marketing#viewed'

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'dashboard#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
