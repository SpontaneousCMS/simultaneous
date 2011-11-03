# encoding: UTF-8

require 'eventmachine'

module Simultaneous
  class Server < EM::Connection

    def self.channel
      @channel ||= EM::Channel.new
    end

    def self.start(connection_string = Simultaneous.connection, options = {})
      Simultaneous.connection = connection_string
      connection = Simultaneous::Connection.new(connection_string, options)
      @server = connection.start_server(self)
    end


    def self.broadcast(data)
      channel << data
    end

    def self.receive_data(data)
      command = Simultaneous::Command.load(data)
      run(command)
    end

    def self.run(command)
      if Command.allowed?(command)
        puts command.debug if $debug
        command.run
      else
        raise PermissionsError, "'#{command.class}' is not an approved command"
      end
    end

    def self.set_pid(task_name, pid)
      pids[task_name] = pid.to_i
    end

    def self.get_pid(task)
      pids[task.name]
    end

    def self.pids
      @pids ||= {}
    end

    def self.kill(task_name, signal="TERM")
      pid = pids[task_name]
      Process.kill(signal, pid) unless pid == 0
    end

    def self.task_complete(task_name)
      pid = pids.delete(task_name)
    end

    def channel
      Simultaneous::Server.channel
    end

    def post_init
      @sid = channel.subscribe { |m| send_data "#{m}\n" }
    end

    def receive_data(data)
      Simultaneous::Server.receive_data(data)
    end

    def unbind
      channel.unsubscribe @sid if @sid
    end
  end
end
