require 'bundler/setup'
require 'eventmachine'
require 'formatador'
require File.expand_path('../message', __FILE__)

channel = ARGV[0]
Formatador.display_line "[light_black]Channel: [light_magenta][bold]#{channel}[/]"


class BroadcastClient# < EM::Connection



  def initialize(channel)
    @channel = channel
    @connection ||= EM.connect('127.0.0.1', 1234, connection_module)
    # @connection.send_data("channel: #{channel}\\n")
  end

  def connection_module
    mod = Module.new do
      include EventMachine::Protocols::LineText2

      def self.client=(client)
        @@client = client
      end

      def receive_line(line)
        @@client.receive(line)
      end

      def unbind
        EventMachine::stop_event_loop
      end
    end
    mod.client = self
    mod
  end

  def connection
    @connection
  end

  def send(message)
    connection.send_data("#{message}\n")
  end


  def receive(message)
    p message
    if message == ""
      notify! if @message
    else
      @message ||= Message.new
      case message
      when /^channel: *(.+)/
        @message.channel = $1
      when /^event: *(.+)/
        @message.event = $1
      when /^data: *(.*)/
        @message << $1
      when /^:/
        # comment
      else
        # malformed request
      end
    end
  end

  def notify!
    if @message.channel == @channel
      subscribers[@message.event].each do |subscriber|
        subscriber.call(@message.data)
      end
    end
    @message = nil
    # Formatador.display "\\n[light_black]Received: [green][bold]#{message.inspect}\\n[light_black]Enter message: [/]"
  end

  def subscribers
    @subscribers ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def subscribe(event, &block)
    subscribers[event.to_sym] << block
  end
end

input = Thread.new do
  loop do
    print "Enter message: "
    message = $stdin.gets.chomp
    @client.send(message)
  end
end

EventMachine.run do
  @client = BroadcastClient.new(channel)
  something = "_____"
  @client.subscribe(:a) do |data|
    puts "AAAAAAAA #{something} #{data.inspect}"
  end

  @client.subscribe(:b) do |data|
    puts "BBBBBBBB #{something} #{data.inspect}"
  end
end
