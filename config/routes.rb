Rails.application.routes.draw do
  resources :lists do
    resources :items
  end
  mount_devise_token_auth_for 'User', at: 'auth'
end
