# encoding: UTF-8

require 'socket'

module Simultaneous
  class SyncClient
    attr_reader :domain

    def initialize(domain = Simultaneous.domain, connection_string=Simultaneous.connection)
      @domain = domain
      @connection = Simultaneous::Connection.new(connection_string)
    end

    def run(command)
      command.domain = self.domain
      send(command.dump)
    end

    def send(command)
      connect do |connection|
        connection.send(command, 0)
      end
    end

    def connect
      @connection.sync_socket do |socket|
        yield(socket)
      end
    end

    def close
    end

    def on_event(event)
    end
  end
end
