# require 'bundler/setup'
require 'eventmachine'
# require 'formatador'
# require File.expand_path('../message', __FILE__)




module FAF
  class Server < EM::Connection

    def self.channel
      @channel ||= EM::Channel.new
    end

    def self.start_unix(socket = FAF::DEFAULT_SOCKET)
      self.start(socket)
    end

    def self.start_tcp(host = DEFAULT_HOST, port = FAF::DEFAULT_PORT)
      self.start(host, port)
    end

    def self.start(*args)
      EventMachine::start_server(*args, self)
    end

    def self.broadcast(data)
      channel << data
    end

    def channel
      FAF::Server.channel
    end

    def post_init
      @sid = channel.subscribe { |m| send_data "#{m}\n" }
    end

    def receive_data(data)
      # Formatador.display "\\n[light_black]Recieved: [green][bold]#{data.inspect}[/]"
    end

    def unbind
      channel.unsubscribe @sid if @sid
    end
  end

  # server = BroadCastServer.new

  # input = Thread.new do
  #   loop do
  #     prompt!
  #     data = $stdin.gets.chomp#.split("/").map { |p| p.strip }
  #     p data
  #     BroadCastServer.broadcast(data)
  #   end
  # end

  # EventMachine.run do
  #   BroadCastServer.start
  # end

end
