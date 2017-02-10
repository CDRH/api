Rails.application.routes.draw do
  root 'default#root', as: :home

  # collections
  get '/collections' => 'collection#index', as: :collections
  get '/collection/{shortname}' => 'collection#show', as: :collection
  get 'collection/{shortname}/info' => 'collection#info', as: :collection_info
  get 'collection/{shortname}/item/{id}' => 'collection#item', as: :collection_item

  # items
  get '/items' => 'item#index', as: :items
  get '/item/{id}' => 'item#show', as: :item
end
