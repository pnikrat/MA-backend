# Api controller for user groups actions
class GroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups
    render json: @groups
  end
end
