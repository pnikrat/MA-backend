# override to invitation gem - authorize group creators to inviting
class InvitesController < Invitation::InvitesController
  before_action :authenticate_user!
  before_action :authorize
  before_action :check_if_permissions_already_exist

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

  def check_if_permissions_already_exist
    return unless user_already_in_group
    render json: custom_error('User already in group'), status: :bad_request
  end

  def user_already_in_group
    GroupMembership.joins(:user).
      where(users: { email: invite_params[:email] }, group_id: invite_params[:invitable_id]).exists?
  end
end
