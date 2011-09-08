require 'bundler/setup'
require 'eventmachine'
require 'formatador'

def prompt!
  Formatador.display "\n[light_black]Channel / Message : [/]"
end

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
    # subscription is only done when we recieve the channel name
    # @sid = RandChannel.subscribe { |m| send_data "#{m}\\n" }
  end

  def receive_data data
    case data
    when /^channel: (\w+)/
      @channel_name = $1
      Formatador.display "\n[light_black]Client bound to channel [light_magenta][bold]#{@channel_name}[/]"
      @channel = BroadCastServer.channels[@channel_name]
      @sid = @channel.subscribe { |m| send_data("#{m}\n") }
      prompt!
    else
      Formatador.display "\n[light_black]Recieved: [green][bold]#{data.inspect}[/]"
      prompt!
    end
  end


  def unbind
    puts "#{@channel_name}.unbind #{@sid.inspect}"
    @channel.unsubscribe @sid
  end

end

# server = BroadCastServer.new

input = Thread.new do
  loop do
    # print "channel / message : "
    prompt!
    channel, message = gets.chomp.split("/").map { |p| p.strip }
    BroadCastServer.broadcast(channel, message)
  end
end

EventMachine.run do
  BroadCastServer.start
end

