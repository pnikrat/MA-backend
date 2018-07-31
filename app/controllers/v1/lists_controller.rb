module V1
  # Api controller for shopping lists
  class ListsController < ApplicationController
    before_action :authenticate_user!
    before_action :find_list, only: %i[show update]
    before_action :find_direct_list, only: %i[destroy]

    include JSONErrors

    def index
      @lists = available_lists
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
      @list = current_user.lists.create(create_list_params)
      if @list.persisted?
        render json: @list, status: :created, location: @list
      else
        render json: errors(@list), status: :bad_request
      end
    end

    def update
      if @list.present?
        if @list.update(create_list_params)
          render json: @list, status: :ok
        else
          render json: errors(@list), status: :bad_request
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

    def create_list_params
      params.permit(:name)
    end

    def available_lists
      List.user_lists(current_user)
    end

    def find_list
      @list = available_lists.find_by(id: params[:id])
    end

    def find_direct_list
      @list = List.where(user: current_user).find_by(id: params[:id])
    end
  end
end
