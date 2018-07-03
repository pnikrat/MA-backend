# Api controller for shopping items
class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_list
  before_action :find_item, only: %i[show update destroy]
  before_action :find_items, only: %i[mass_action]
  before_action :find_target_list, only: %i[mass_action update]

  include JSONErrors

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
      ws_event(:create_item, @item)
      render json: @item, status: :created,
             location: list_item_url(@list, @item)
    else
      render json: errors(@item), status: :bad_request
    end
  end

  def update
    if @item.present?
      if !can_access_target_list?
        render json: unauthorized_error, status: :unauthorized
      elsif item_update
        render json: @item, status: :ok
      else
        render json: errors(@item), status: :bad_request
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
      if !can_access_target_list?
        render json: unauthorized_error, status: :unauthorized
      elsif items_update
        render json: @items, status: :ok
      else
        render json: custom_error(map_errors), status: :bad_request
      end
    else
      render status: :no_content
    end
  end

  private

  def create_item_params
    params.permit(:name, :quantity, :price, :unit)
  end

  def can_access_target_list?
    return true if @target_list.blank?
    List.user_lists(current_user).include? @target_list
  end

  def item_update(item = nil)
    item ||= @item
    item.list = @target_list if @target_list.present?
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
    @list = List.user_lists(current_user).find_by(id: params[:list_id])
    render status: :no_content if @list.nil?
  end

  def find_item
    @item = Item.where(list: @list).find_by(id: params[:id])
  end

  def find_items
    @items = Item.where(list: @list, id: params[:ids])
  end

  def find_target_list
    return if params[:target_list].blank?
    @target_list = List.find(params[:target_list])
  end

  def map_errors
    @items.map { |i| i.errors.full_messages }.flatten.compact
  end

  def ws_event(event_type, data)
    ListChannel.broadcast_to(@list, { event_type: event_type, data: data }.to_json)
  end
end
