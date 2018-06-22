# Api controller for user groups actions
class GroupsController < ApplicationController
  before_action :authenticate_user!

  include JSONErrors

  def index
    @groups = current_user.groups
    render json: @groups
  end

  def show
    @group = Group.with_member(current_user).find_by(id: params[:id])
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

  def update
    @group = Group.find_by(id: params[:id], creator: current_user)
    if @group.present?
      if @group.update(group_params)
        render json: @group, status: :ok
      else
        render json: errors(@group), status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end
end
