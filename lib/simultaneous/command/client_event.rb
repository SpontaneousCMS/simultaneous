# encoding: UTF-8

module Simultaneous
  module Command
    class ClientEvent < CommandBase

      def initialize(domain, event, data)
        @domain, @event, @data = domain, event, data
      end

      def run
        message = Simultaneous::BroadcastMessage.new({
          :domain => @domain,
          :event => @event,
          :data => @data
        })
        Simultaneous::Server.broadcast(message.to_event)
      end
      def debug
        "ClientEvent: #{@domain}:#{@event} #{@data.inspect}\n"
      end
    end
  end
end
