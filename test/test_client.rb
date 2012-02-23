require File.expand_path('../helper', __FILE__)

describe Simultaneous::AsyncClient do
  it "should send right command to server" do
    EM.run {
      task = Simultaneous.add_task(:publish, "/publish", {:param1 => "value1", :param2 => "value2"}, 12)
      command = Object.new
      mock(command).domain=("faf.org")
      mock(command).dump { "dumpedcommand" }
      mock(Simultaneous::Command::Fire).new(task, {:param2 => "value3"}) { command }

      Simultaneous.domain = "faf.org"
      Simultaneous.connection = SOCKET
      Simultaneous::Server.start

      mock(Simultaneous::Server).receive_data("dumpedcommand") { EM.stop }

      Thread.new {
        pid = Simultaneous.publish({:param2 => "value3"})
      }.join
    }
  end

end
