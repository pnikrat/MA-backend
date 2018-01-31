# Api controller for shopping lists
class ListsController < ApplicationController
  before_action :authenticate_user!

  def index
    @lists = List.where(user: current_user)
    render json: @lists
  end
end
