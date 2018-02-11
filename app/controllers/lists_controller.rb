# Api controller for shopping lists
class ListsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_list, only: %i[show update destroy]

  def index
    @lists = List.where(user: current_user)
    render json: @lists
  end

  def show
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

  def update
    if @list.present?
      if @list.update(create_list_params)
        render json: @list, status: :ok
      else
        render json: @list.errors, status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  def destroy
    if @list.present?
      @list.destroy
      render status: :ok
    else
      render status: :no_content
    end
  end

  private

  def list_params
    params.require(:id)
  end

  def create_list_params
    params.permit(:name)
  end

  def find_list
    @list = List.where(user: current_user).find_by(id: list_params)
  end
end
