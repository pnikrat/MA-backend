# Api controller for user groups actions
class GroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups
    render json: @groups
  end

  def show
    @group = Group.where(id: params[:id]).with_member(current_user)
    if @group.present?
      render json: @group, include: :users
    else
      render status: :no_content
    end
  end
end
