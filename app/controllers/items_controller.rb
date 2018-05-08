# Api controller for shopping items
class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_list
  before_action :find_item, only: %i[show update destroy toggle]

  def index
    @items =
      if item_query_params.blank?
        @list.items
      else
        @list.items.search(item_query_params[:name])
      end
    render json: @items
  end

  def show
    if @item.present?
      render json: @item
    else
      render status: :no_content
    end
  end

  def create
    @item = @list.items.create(create_item_params)
    if @item.persisted?
      render json: @item, status: :created,
             location: list_item_url(@list, @item)
    else
      render json: @item.errors, status: :bad_request
    end
  end

  def update
    if @item.present?
      if item_update!
        render json: @item, status: :ok
      else
        render json: @item.errors, status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  def destroy
    if @item.present?
      @item.destroy
      render status: :ok
    else
      render status: :no_content
    end
  end

  def toggle
    if @item.present?
      if @item.change_state(toggle_item_params[:state])
        render json: @item, status: :ok
      else
        render json: @item.errors, status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  private

  def list_params
    params.require(:list_id)
  end

  def item_params
    params.require(:id)
  end

  def item_query_params
    params.permit(:name)
  end

  def create_item_params
    params.permit(:name, :quantity, :price, :unit)
  end

  def toggle_state_params
    params.permit(:state)
  end

  def item_update!
    @item.state = toggle_state_params[:state] if toggle_state_params.present?
    @item.update(create_item_params)
  end

  def find_list
    @list = List.where(user: current_user).find_by(id: list_params)
    render status: :no_content if @list.nil?
  end

  def find_item
    @item = Item.where(list: @list).find_by(id: item_params)
  end
end
