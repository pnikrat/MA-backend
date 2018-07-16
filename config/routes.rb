Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  resources :lists do
    resources :items do
      collection do
        put :update, action: :mass_action
        patch :update, action: :mass_action
      end
    end
  end

  resources :groups
  resources :invites, controller: 'overrides/invites', only: %i[create]

  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'overrides/registrations'
  }
end
