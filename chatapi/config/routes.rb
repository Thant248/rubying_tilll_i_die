Rails.application.routes.draw do

  # mount_devise_token_auth_for 'User', at: 'auth'
  namespace :v1 do
    get 'rooms/show'
    mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        registrations: 'v1/auth/registrations'
    }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  # get 'rooms/show'
end
