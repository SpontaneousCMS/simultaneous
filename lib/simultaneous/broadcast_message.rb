# encoding: UTF-8

module Simultaneous
  class BroadcastMessage
    attr_accessor :domain, :id
    attr_reader :event

    def initialize(values = {})
      @domain = (values[:domain] || values["domain"])
      @event = nil
      if (event = (values[:event] || values["event"])) and !event.empty?
        self.event = event
      end
      self.data = (values[:data] || values["data"] || "")
      self.id = (values[:id] || next_id)
    end

    def next_id
      SecureRandom.uuid
    end

    def event=(event)
      @event = event.to_s
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
      when /^id: *(.+)/
        @id = $1
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
      lines = ["domain: #{domain}"]
      lines.concat(event_content)
      lines.join("\n")
    end

    def to_sse
      event_content.join("\n")
    end

    def event_content
      lines = ["event: #{event}", "id: #{id}"]
      lines.concat(@data.map { |l| "data: #{l}" })
      lines.push("\n")
    end
  end
end
