require 'bundler/setup'
require 'eventmachine'

class BroadCastServer < EM::Connection
  # RandChannel = EM::Channel.new
  def self.channels
    @channels ||= Hash.new { |hash, key| hash[key] = EM::Channel.new }
  end

  def self.start(host = "0.0.0.0", port = 1234)
    EventMachine::start_server(host, port, self)
  end

  def self.broadcast(channel, message)
    channels[channel] << message
  end

  def post_init
    # @sid = RandChannel.subscribe { |m| send_data "#{m}\\n" }
  end

  def receive_data data
    p data
    case data
    when /^channel: (\w+)/
      puts "binding to channel #{$1}"
      @channel = BroadCastServer.channels[$1]
      @sid = @channel.subscribe { |m| send_data("#{m}\n") }
    else
      print "\n:data: #{data.inspect}\nEnter message: "
    end
  end

  def unbind
    puts "unbind #{@sid.inspect}"
    @channel.unsubscribe @sid
  end

end

# server = BroadCastServer.new

input = Thread.new do
  loop do
    print "channel / message : "
    channel, message = gets.chomp.split("/").map { |p| p.strip }
    BroadCastServer.broadcast(channel, message)
  end
end

EventMachine.run do
  BroadCastServer.start
end

