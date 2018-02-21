Rails.application.routes.draw do
  resources :lists do
    resources :items do
      member do
        put 'toggle'
      end
    end
  end
  mount_devise_token_auth_for 'User', at: 'auth'
end
