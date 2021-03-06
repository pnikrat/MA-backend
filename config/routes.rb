Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  scope module: :v1, constraints: ApiConstraint.new(version: 1, default: true) do
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
      registrations: 'v1/overrides/registrations'
    }
  end
end
