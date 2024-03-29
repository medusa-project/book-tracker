Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post],
        as: 'auth' # used by omniauth
  match "/auth/failure", to: "sessions#auth_failed", as: :auth_failed, via: [:get, :post]
  match '/signout', to: 'sessions#destroy', via: :delete

  match 'books', to: 'books#index', as: :books, via: [:get, :post]
  match 'books/:id', to: 'books#show', as: :book, via: :get
  resources 'tasks', only: :index

  match 'check-google', to: 'tasks#check_google', via: :post,
        as: 'check_google'
  match 'import', to: 'tasks#import', via: :post

  match '/', to: redirect('/books'), via: :get, as: 'root'

  # Dedicated health check URL because `/` returns 3xx
  match '/health', to: 'health#check', via: :get
  match '/error', to: 'health#error', via: :get

end
