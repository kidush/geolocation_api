Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :geolocations, only: [ :index, :create ]
  delete "geolocations", to: "geolocations#destroy"

  match "*path", to: "errors#not_found", via: :all
end
