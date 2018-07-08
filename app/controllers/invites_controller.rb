# override to invitation gem - authorize group creators to inviting
class InvitesController < Invitation::InvitesController
  before_action :authenticate_user!
  before_action :authorize

  include JSONErrors
  include ActionController::MimeResponds

  private

  def authorize
    group = load_invitable
    render json: unauthorized_error, status: :unauthorized unless group.can_invite?(current_user)
  end

  def load_invitable
    invite_params[:invitable_type].classify.constantize.find(invite_params[:invitable_id])
  end
end
