# Api controller for user groups actions
class GroupsController < ApplicationController
  before_action :authenticate_user!

  include JSONErrors

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

  def create
    @group = current_user.groups.create group_params.merge(creator: current_user)
    if @group.persisted?
      render json: @group, status: :created, location: @group
    else
      render json: errors(@group), status: :bad_request
    end
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end
end
