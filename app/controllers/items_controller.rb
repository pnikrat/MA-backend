# Api controller for shopping items
class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_list
  before_action :find_item, only: %i[show update destroy]
  before_action :find_items, only: %i[mass_action]

  def index
    @items =
      if params[:name].blank?
        @list.items
      else
        @list.items.search(params[:name])
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
      if item_update
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

  def mass_action
    if @items.present?
      if items_update
        render json: @items, status: :ok
      else
        render json: map_errors, status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  private

  def create_item_params
    params.permit(:name, :quantity, :price, :unit)
  end

  def item_update(item = nil)
    item ||= @item
    item.state = params[:state] if params[:state].present?
    item.update(create_item_params)
  end

  def items_update
    Item.transaction do
      @items.each do |i|
        update_successful = item_update i
        raise ActiveRecord::Rollback unless update_successful
      end
    end
  end

  def find_list
    @list = List.where(user: current_user).find_by(id: params[:list_id])
    render status: :no_content if @list.nil?
  end

  def find_item
    @item = Item.where(list: @list).find_by(id: params[:id])
  end

  def find_items
    @items = Item.where(list: @list, id: params[:ids])
  end

  def map_errors
    @items.map { |i| [i, i.errors] }
  end
end
