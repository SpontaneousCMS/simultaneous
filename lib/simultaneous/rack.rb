# encoding: UTF-8

require 'rack/async'

module Simultaneous
  module Rack
    # A Rack handler that allows you to create a HTML5 Server-Sent Events
    # endpoint. Relies on EventMachine to easily handle multiple
    # open connections simultaneously
    #
    # To use, first create an instance of the EventSource class:
    #
    #   messenger = Simultaneous::Rack::EventSource.new
    #
    # Then map this onto a URL in your application, e.g. in a RackUp file
    #
    #   app = ::Rack::Builder.new do
    #     map "/messages" do
    #       run messenger.app
    #     end
    #   end
    #   run app
    #
    # In your web-page, set up an EventSource using the new APIs
    #
    #   source = new EventSource('/messages');
    #   source.addEventListener('message', function(e) {
    #     alert(e.data);
    #   }, false);
    #
    #
    # Then when you want to send a messages to all your clients you
    # use your (Ruby) EventSource instance like so:
    #
    #   messenger.deliver("Hello!")
    #
    # IMPORTANT:
    #
    # This will only work when run behind Thin or some other, EventMachine
    # driven webserver. See <https://github.com/matsadler/rack-async> for more
    # info.
    #
    class EventSource

      def initialize
        @lock = Mutex.new
        @timer = nil
        @clients = []
      end

      def app
        ::Rack::Async.new(self)
      end

      def call(env)
        stream = env['async.body']
        stream.errback { cleanup!(stream) }

        @lock.synchronize { @clients << stream }

        # Nginx specific header to disable buffering
        # see: http://wiki.nginx.org/X-accel#X-Accel-Buffering
        [200, {"Content-type" => "text/event-stream", "X-Accel-Buffering" => "no"}, stream]
      end

      def deliver_event(event)
        send(event.to_sse)
      end

      def deliver(data)
        send("data: #{data}\n\n")
      end

      private

      def send(message)
        @clients.each { |client| client << message }
      end

        def cleanup!(connection)
          @lock.synchronize { @clients.delete(connection) }
        end
      end
    end
  end
