require 'bundler/setup'
require 'eventmachine'

p ARGV
$channel = ARGV[0]
puts "Channel: #{$channel}"


module BroadcastClient
  def self.start
    @connection ||= EM.connect('127.0.0.1', 1234, self)
    @connection.send_data("channel: #{$channel}\n")
  end

  def self.connection
    @connection
  end

  def self.send(message)
    p message
    connection.send_data("#{message}\n")
  end

  def self.receive(message)
    print "\n<<: #{message.inspect}\nEnter message: "
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
  BroadcastClient.start
end
