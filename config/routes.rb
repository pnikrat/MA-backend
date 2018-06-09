Rails.application.routes.draw do
  resources :lists do
    resources :items do
      collection do
        put :update, action: :mass_action
        patch :update, action: :mass_action
      end
    end
  end
  mount_devise_token_auth_for 'User', at: 'auth'
end
