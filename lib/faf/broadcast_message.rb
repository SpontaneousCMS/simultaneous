module FAF
  class BroadcastMessage
    attr_accessor :channel
    attr_reader :event

    def initialize(values = {})
      @channel = (values[:channel] || values["channel"])
      @event = nil
      if (event = (values[:event] || values["event"])) and !event.empty?
        self.event = event
      end
      self.data = (values[:data] || values["data"] || "")
    end

    def event=(event)
      @event = event.to_sym
    end

    def data=(data)
      @data = data.split(/\r\n?|\n\r?/)
    end

    def data
      @data.join("\n").chomp
    end

    def <<(line)
      data = line.chomp
      case data
      when /^channel: *(.+)/
        self.channel = $1
      when /^event: *(.+)/
        self.event = $1
      when /^data: *(.*)/
        @data << $1
      when /^:/
        # comment
      else
        # malformed request
      end
    end

    def valid?
      @channel && @event && !@data.empty?
    end

    def to_src
      lines = ["channel: #{channel}", "event: #{event}"]
      lines.concat(@data.map { |l| "data: #{l}" })
      lines.push("\n")
      lines.join("\n")
    end
  end
end
