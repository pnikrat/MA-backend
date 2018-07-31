module V1
  module Overrides
    # open devise token auth registrations controller to process group invite token
    class RegistrationsController < DeviseTokenAuth::RegistrationsController
      include Invitation::UserRegistration
      # @resource is an instance of User
      after_action -> { process_invite_token(@resource) }, only: %i[create]
    end
  end
end
