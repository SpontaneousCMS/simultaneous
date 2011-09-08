require 'bundler/setup'
require 'eventmachine'
require 'formatador'
require File.expand_path('../message', __FILE__)

def prompt!
  Formatador.display "\n[light_black]:: [/]"
end

class BroadCastServer < EM::Connection

  def self.channel
    @channel ||= EM::Channel.new
  end

  def self.start(host = "0.0.0.0", port = 1234)
    EventMachine::start_server(host, port, self)
  end

  def self.broadcast(data)
    channel << data
  end

  def channel
    BroadCastServer.channel
  end

  def post_init
    @sid = channel.subscribe { |m| send_data "#{m}\n" }
  end

  def receive_data(data)
    Formatador.display "\n[light_black]Recieved: [green][bold]#{data.inspect}[/]"
    prompt!
  end

  def unbind
    puts "\nUnbind #{@sid.inspect}"
    channel.unsubscribe @sid if @sid
    prompt!
  end
end

# server = BroadCastServer.new

input = Thread.new do
  loop do
    prompt!
    data = $stdin.gets.chomp#.split("/").map { |p| p.strip }
    p data
    BroadCastServer.broadcast(data)
  end
end

EventMachine.run do
  BroadCastServer.start
end

