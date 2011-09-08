class Message
  attr_accessor :channel, :event

  def initialize
    @channel = nil
    @event = nil
    @data = []
  end

  def <<(data)
    @data << data
  end

  def data
    @data.join
  end

  def event=(event)
    @event = event.to_sym
  end

  def to_event
    lines = ["channel: #{channel}", "event: #{event}"]
    lines.concat(data.map { |l| "data: #{l}" })
    lines.join("\n")
  end
end

