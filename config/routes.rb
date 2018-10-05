Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  match 'books', to: 'books#index', as: :books, via: [:get, :post]
  match 'books/:id', to: 'books#show', as: :book, via: :get
  resources 'tasks', only: :index

  match 'check-google', to: 'tasks#check_google', via: :post,
        as: 'check_google'
  match 'check-hathitrust', to: 'tasks#check_hathitrust', via: :post,
        as: 'check_hathitrust'
  match 'check-internet-archive', to: 'tasks#check_internet_archive',
        via: :post, as: 'check_internet_archive'
  match 'import', to: 'tasks#import', via: :post

  match '/', to: redirect('/books'), via: :get

end
