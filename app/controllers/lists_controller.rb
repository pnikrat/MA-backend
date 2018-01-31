# Api controller for shopping lists
class ListsController < ApplicationController
  before_action :authenticate_user!

  def index
    @lists = List.where(user: current_user)
    render json: @lists
  end

  def show
    @list = List.where(user: current_user).find_by(id: list_params)
    if @list.present?
      render json: @list
    else
      render status: :no_content
    end
  end

  def create
    @list = current_user.lists.create(name: create_list_params[:name])
    if @list.persisted?
      render json: @list, status: :created, location: @list
    else
      render json: @list.errors, status: :bad_request
    end
  end

  private

  def list_params
    params.require(:id)
  end

  def create_list_params
    params.permit(:name)
  end
end
