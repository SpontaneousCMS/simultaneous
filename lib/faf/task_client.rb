# encoding: UTF-8

require 'socket'

module FireAndForget
  class TaskClient
    attr_reader :domain

    def initialize(domain = FAF.domain, connection_string=FAF.connection)
      @domain = domain
      @connection_string = connection_string
    end

    def run(command)
      puts "TaskClient#run"
      p command
      command.domain = self.domain
      send(command.dump)
    end

    def send(command)
      connect do |connection|
        connection.send(command, 0)
      end
    end

    def connect
      connection = nil
      begin
        connection = FAF.client_connection(@connection_string)
        yield(connection)
        connection.flush
        connection.close_write
      ensure
        connection.close if connection rescue nil
      end
    end

    def close
    end

    def on_event(event)
    end
  end
end
