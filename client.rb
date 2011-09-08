require 'bundler/setup'
require 'eventmachine'
require 'formatador'

channel = ARGV[0]
Formatador.display_line "[light_black]Channel: [light_magenta][bold]#{channel}[/]"


module BroadcastClient
  def self.start(channel)
    @connection ||= EM.connect('127.0.0.1', 1234, self)
    @connection.send_data("channel: #{channel}\n")
  end

  def self.connection
    @connection
  end

  def self.send(message)
    connection.send_data("#{message}\n")
  end

  def self.receive(message)
    Formatador.display "\n[light_black]Received: [green][bold]#{message.inspect}\n[light_black]Enter message: [/]"
  end

  include EventMachine::Protocols::LineText2

  def receive_line(line)
    BroadcastClient.receive(line)
  end

  def unbind
    EventMachine::stop_event_loop
  end
end

input = Thread.new do
  loop do
    print "Enter message: "
    message = $stdin.gets.chomp
    BroadcastClient.send(message)
  end
end

EventMachine.run do
  BroadcastClient.start(channel)
end
