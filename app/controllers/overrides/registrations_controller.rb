module DeviseTokenAuth
  # open devise token auth registrations controller to process group invite token
  class RegistrationsController
    include Invitation::UserRegistration
    after_action :process_invite_token, only: %i[create]
  end
end
