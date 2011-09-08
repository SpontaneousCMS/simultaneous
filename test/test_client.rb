require File.expand_path('../helper', __FILE__)

describe FireAndForget::Client do
  it "should send right command to server" do
    EM.run {
      task = FAF.add_task(:publish, "/publish", {:param1 => "value1", :param2 => "value2"}, 12)
      command = Object.new
      mock(command).dump { "dumpedcommand" }
      mock(FAF::Command::Fire).new(task, {:param2 => "value3"}) { command }

      FAF.socket = SOCKET
      FAF::Server.start_unix

      mock(FAF::Server).receive_data("dumpedcommand\n") { EM.stop }

      Thread.new {
        pid = FAF.publish({:param2 => "value3"})
      }.join
    }
  end

end
