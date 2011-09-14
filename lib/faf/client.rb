# encoding: UTF-8

require 'eventmachine'

module FAF
  class Client


    attr_reader :connection, :domain

    def initialize(domain, connection_string, &block)
      @connection_string = connection_string
      @domain = domain
      @callbacks = []
      @connection = nil
      connect
    end

    def handler
      handler = Class.new(EventMachine::Connection) do
        include EventMachine::Protocols::LineText2

        def client=(client); @client = client end
        def client; @client end

        def receive_line(line)
          puts "receieved #{line.inspect}"
          client.receive(line)
        end
      end
      handler
    end

    def close
      puts "Client.close"
      @connection.close_connection_after_writing if @connection
    end

    def run(command)
      puts "RUN #{command.inspect}"
      command.domain = self.domain
      send(command.dump)
    end

    def send(message)
      connection do |c|
        puts "Sending #{message.inspect}"
        p c
        c.send_data(message)
      end
    end

    def connection(&callback)
      # if @connection
      #   puts "CONNECTION #{callback}"
        callback.call(@connection)
      # else
      #   puts "DEFERRED #{callback} #{@callbacks.length}"
      #   @callbacks << callback
      #   # connect
      # end
    end

    def connect
      event_machine do
        EventMachine.connect(*FAF.parse_connection(@connection_string), handler) do |conn|
          conn.client = self
          puts "CONNECTED #{@callbacks.length}"
          @connection = conn
          # @callbacks.each { |block| block.call(conn) }
          # @callbacks = []
        end
      end
    end

    def receive(data)
      if data == ""
        notify! if @message
      else
        @message ||= FAF::BroadcastMessage.new
        @message << data
      end
    end

    def notify!
      if @message.valid? and @message.domain == @domain
        subscribers[@message.event].each do |subscriber|
          subscriber.call(@message.data)
        end
      end
      @message = nil
    end

    def subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def on_event(event, &block)
      subscribers[event.to_sym] << block
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
