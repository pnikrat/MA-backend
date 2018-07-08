# Main dispatcher class
class Dispatcher
  def initialize(channel_class_name)
    @channel = channel_class_name
  end

  def dispatch(target, event_type, data)
    event_type = event_type.to_s.upcase
    @channel.broadcast_to(target, { event_type: event_type, data: data }.to_json)
  end
end
