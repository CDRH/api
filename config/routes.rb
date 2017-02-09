Rails.application.routes.draw do
  root 'default#root', as: :home
  get '/collections' => 'collection#index', as: :collections
end
