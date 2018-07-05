# event dispatching to ListChannel
class ListDispatcher
  def initialize(target)
    @target = target
    @service = Dispatcher.new(ListChannel)
  end

  def ws_event(event_type, data)
    @service.dispatch(@target, event_type, data)
  end
end
