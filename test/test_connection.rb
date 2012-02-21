require File.expand_path('../helper', __FILE__)

describe Simultaneous::Connection do

  after do
    # FileUtils.rm( "/tmp/socket.sock") if File.exist?( "/tmp/socket.sock")
  end

  it "should allow me to generate a connection string from host & port values" do
    Simultaneous::Connection.tcp("localhost", 999).must_equal "localhost:999"
  end
  it "should be correct recognise TCP connections" do
    %w(127.0.0.1:9999 localhost:1234 123.239.23.1:9999 host.domain.com:9999).each do |c|
      Simultaneous::Connection.new(c).tcp?.must_be :==, true
      Simultaneous::Connection.new(c).unix?.must_be :==, false
    end
  end

  it "should be correct recognise UNIX connections" do
    %w(/path/to/socket.sock socket file.sock).each do |c|
      Simultaneous::Connection.new(c).tcp?.must_be :==, false
      Simultaneous::Connection.new(c).unix?.must_be :==, true
    end
  end

  it "should open an EventMachine TCP server connection" do
    conn = Simultaneous::Connection.new("127.0.0.1:9999")
    handler = Object.new
    mock(EventMachine).start_server("127.0.0.1", 9999, handler)
    conn.start_server(handler)
  end
  it "should open an EventMachine TCP client connection" do
    conn = Simultaneous::Connection.new("127.0.0.1:9999")
    handler = Object.new
    mock(EventMachine).connect("127.0.0.1", 9999, handler)
    conn.async_socket(handler)
  end

  it "should open an synchronous TCP client connection" do
    conn = Simultaneous::Connection.new("127.0.0.1:9999")
    socket = Object.new
    mock(socket).write("string")
    mock(socket).flush
    mock(socket).close_write
    mock(socket).close
    mock(TCPSocket).new("127.0.0.1", 9999) { socket }
    conn.sync_socket do |s|
      s.write("string")
    end
  end

  it "should open an EventMachine Unix server connection" do
    conn = Simultaneous::Connection.new("/tmp/socket.sock")
    handler = Object.new
    mock(EventMachine).start_server("/tmp/socket.sock", handler)
    conn.start_server(handler)
  end
  it "should open an EventMachine Unix client connection" do
    conn = Simultaneous::Connection.new("/tmp/socket.sock")
    handler = Object.new
    mock(EventMachine).connect("/tmp/socket.sock", handler)
    conn.async_socket(handler)
  end

  it "should open an synchronous Unix client connection" do
    conn = Simultaneous::Connection.new("/tmp/socket.sock")
    socket = Object.new
    mock(socket).write("string")
    mock(socket).flush
    mock(socket).close_write
    mock(socket).close
    mock(UNIXSocket).new("/tmp/socket.sock") { socket }
    conn.sync_socket do |s|
      s.write("string")
    end
  end

  it "should set the correct permissions on the EventMachine server socket" do
    socket = "/tmp/socket.sock"
    gid = "789"
    FileUtils.rm(socket) if File.exist?(socket)
    mock(File).chmod(0777, socket)
    mock(File).chown(nil, gid, socket)
    handler = Module.new
    mock(EventMachine).start_server(socket, handler) { FileUtils.touch(socket) }
    conn = Simultaneous::Connection.new(socket, {:gid => gid})
    conn.start_server(handler)
    FileUtils.rm(socket) if File.exist?(socket)
  end

end
