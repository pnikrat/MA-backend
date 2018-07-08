# channel for events from observed list
class ListChannel < ApplicationCable::Channel
  def subscribed
    @list = find_list
    reject unless @list
    stream_for @list
  end

  private

  def find_list
    List.user_lists(current_user).find_by(id: params[:list_id])
  end
end
