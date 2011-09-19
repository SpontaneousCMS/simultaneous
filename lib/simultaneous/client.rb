# encoding: UTF-8

require 'eventmachine'

module Simultaneous
  class Client


    attr_reader :domain

    def initialize(domain, connection_string, &block)
      @connection = Simultaneous::Connection.new(connection_string)
      @domain = domain
      @callbacks = []
      @socket = nil
      connect
    end

    def handler
      handler = Class.new(EventMachine::Connection) do
        include EventMachine::Protocols::LineText2

        def client=(client); @client = client end
        def client; @client end

        def connection_completed
          # $stdout.puts "Client connection completed\\n"
        end

        def receive_line(line)
          client.receive(line)
        end

        # def unbind
        #   $stdout.puts "Client Connection closed\\n"
        #   client.reconnect!
        # end
      end
      handler
    end

    def reconnect!
      @socket = nil
      connect
    end

    def close
      @socket.close_connection_after_writing if @socket
    end

    def run(command)
      command.domain = self.domain
      send(command.dump)
    end

    def send(message)
      connection do |c|
        c.send_data(message)
      end
    end

    def connection(&callback)
      callback.call(@socket) if @socket
    end

    def connect
      event_machine do
        # EventMachine.connect(*Simultaneous.parse_connection(@connection_string), handler) do |conn|
        @connection.async_socket(handler) do |conn|
          conn.client = self
          @socket = conn
        end
      end
    end

    def receive(data)
      if data == ""
        notify! if @message
      else
        @message ||= Simultaneous::BroadcastMessage.new
        @message << data
      end
    end

    def notify!
      if @message.valid? and @message.domain == @domain
        subscribers[@message.event].each do |subscriber|
          subscriber.call(@message)
        end
      end
      @message = nil
    end

    def subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def on_event(event, &block)
      subscribers[event.to_s] << block
    end

    def event_machine(&block)
      if EM.reactor_running?
        block.call
      else
        Thread.new { EM.run }
        EM.next_tick { block.call }
      end
    end
  end
end
