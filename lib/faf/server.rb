# encoding: UTF-8

module FAF
  class Server < EM::Connection

    def self.channel
      @channel ||= EM::Channel.new
    end

    def self.start_unix(socket = FAF.socket)
      self.start(socket)
    end

    def self.start_tcp(host = DEFAULT_HOST, port = FAF::DEFAULT_PORT)
      self.start(host, port)
    end

    def self.start(*args)
      EventMachine::start_server(*args, self)
    end

    def self.broadcast(data)
      puts "broadcast"
      p data
      channel << data
    end

    def self.receive_data(data)
      command = FAF::Command.load(data)
      run(command)
    end

    def self.run(command)
      if Command.allowed?(command)
        puts command.debug if $debug
        puts "running"
        p command
        command.run
      else
        raise PermissionsError, "'#{command.class}' is not an approved command"
      end
    end

    def self.status
      @status ||= {}
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


    def channel
      FAF::Server.channel
    end

    def post_init
      @sid = channel.subscribe { |m| send_data "#{m}\n" }
    end

    def receive_data(data)
      FAF::Server.receive_data(data)
    end

    def unbind
      channel.unsubscribe @sid if @sid
    end
  end
end
