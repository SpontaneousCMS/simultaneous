# encoding: UTF-8

module FireAndForget
  class Connection
    TCP_CONNECTION_MATCH = %r{^([^/]+):(\d+)}

    def initialize(connection_string)
      connection_string = connection_string
      @tcp = false
      if connection_string =~ TCP_CONNECTION_MATCH
        @tcp = true
        @host, @port = $1, $2.to_i
      else
        @socket = connection_string
      end
    end

    def tcp?
      @tcp
    end

    def unix?
      !@tcp
    end

    def start_server(handler, &block)
      if tcp?
        EventMachine::start_server(@host, @port, handler, &block)
      else
        EventMachine::start_server(@socket, handler, &block)
        set_socket_permissions(@socket)
      end
    end

    def async_socket(handler, &block)
      if tcp?
        EventMachine.connect(@host, @port, handler, &block)
      else
        EventMachine.connect(@socket, handler, &block)
      end
    end

    def sync_socket
      socket = open_sync_socket
      if block_given?
        begin
          yield(socket)
          socket.flush
          socket.close_write
        ensure
          socket.close if socket rescue nil
        end
      end
      socket
    end

    def open_sync_socket
      if tcp?
        TCPSocket.new(@host, @port)
      else
        UNIXSocket.new(@socket)
      end
    end

    def set_socket_permissions(socket)
      File.chmod(0770, socket) if File.exist?(socket)
    end
  end
end
