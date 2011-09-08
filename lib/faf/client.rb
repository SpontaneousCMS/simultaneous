require 'eventmachine'


module FAF
  class Client

    def self.socket_client(channel, socket = FAF::DEFAULT_SOCKET)
      self.new(channel, socket)
    end

    def self.tcp_client(channel, host = DEFAULT_HOST, port = FAF::DEFAULT_PORT)
      self.new(channel, host, port)
    end

    attr_reader :connection

    def initialize(channel, *args)#(channel, socket_file)
      @channel = channel
      @connection = EventMachine.connect(*args, handler) do |connection|
        connection.client = self
      end
    end

    def handler
      handler = Class.new(EventMachine::Connection) do
        include EventMachine::Protocols::LineText2

        def client=(client); @client = client end
        def client; @client end


        def receive_line(line)
          client.receive(line)
        end
      end

      # handler.client = self
      handler
    end

    def send(message)
      connection.send_data("#{message}\n")
    end


    def receive(data)
      p data
      if data == ""
        notify! if @message
      else
        @message ||= FAF::BroadcastMessage.new
        @message << data
      end
    end

    def notify!
      if @message.valid? and @message.channel == @channel
        subscribers[@message.event].each do |subscriber|
          subscriber.call(@message.data)
        end
      end
      @message = nil
    end

    def subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def subscribe(event, &block)
      subscribers[event.to_sym] << block
    end
  end

  # input = Thread.new do
  #   loop do
  #     print "Enter message: "
  #     message = $stdin.gets.chomp
  #     @client.send(message)
  #   end
  # end

  # EventMachine.run do
  #   @client = BroadcastClient.new(channel)
  #   # test for binding inside blocks
  #   something = "_____"

  #   @client.subscribe :a do |data|
  #     puts "AAAAAAAA #{something} #{data.inspect}"
  #   end

  #   @client.subscribe :b do |data|
  #     puts "BBBBBBBB #{something} #{data.inspect}"
  #   end
  # end
end
