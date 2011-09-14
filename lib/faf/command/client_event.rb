# encoding: UTF-8

module FireAndForget
  module Command
    class ClientEvent < CommandBase

      def initialize(domain, event, data)
        @domain, @event, @data = domain, event, data
      end

      def run
        message = FAF::BroadcastMessage.new({
          :domain => @domain,
          :event => @event,
          :data => @data
        })
        FAF::Server.broadcast(message.to_event)
      end
    end
  end
end
