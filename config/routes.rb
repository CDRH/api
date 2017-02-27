id_regex = /[^\/]+/
Rails.application.routes.draw do
  root 'default#root', as: :home

  # collections
  get '/collections' => 'collection#index', as: :collections
  get '/collection/:shortname' => 'collection#show', as: :collection

  # items
  get '/items' => 'item#index', as: :items
  get '/item/:id' => 'item#show', as: :item, :constraints => { :id => id_regex }
  get '/collection/:shortname/item/:id' => 'item#show', as: :collection_item, :constraints => { :id => id_regex }
  get '/collection/:shortname/items' => 'item#index', as: :collection_items
end
