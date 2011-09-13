# encoding: UTF-8

module FAF
  class BroadcastMessage
    attr_accessor :domain
    attr_reader :event

    def initialize(values = {})
      @domain = (values[:domain] || values["domain"])
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
      when /^domain: *(.+)/
        self.domain = $1
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
      @domain && @event && !@data.empty?
    end

    def to_event
      lines = ["domain: #{domain}", "event: #{event}"]
      lines.concat(@data.map { |l| "data: #{l}" })
      lines.push("\n")
      lines.join("\n")
    end
  end
end
