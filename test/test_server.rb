require File.expand_path('../helper', __FILE__)

describe Simultaneous::Server do
  before do
    Simultaneous.reset!
  end

  after do
    FileUtils.rm(SOCKET) if File.exist?(SOCKET)
  end

  describe "task messages" do
    it "should generate events in clients on the right domain" do
      client1 = client2 = client3 = nil
      result1 = result2 = result3 = nil
      result4 = result5 = result6 = nil

      EM.run {
        Simultaneous::Server.start(SOCKET)

        client1 = Simultaneous::Client.new("domain1", SOCKET)
        client2 = Simultaneous::Client.new("domain1", SOCKET)
        client3 = Simultaneous::Client.new("domain2", SOCKET)

        command = Simultaneous::Command::ClientEvent.new("domain1", "a", "data")

        client1.on_event(:a) { |event| result1 = [:a, event.data] }
        client2.on_event(:a) { |event| result2 = [:a, event.data] }
        client3.on_event(:a) { |event| result3 = [:a, event.data] }
        client1.on_event(:b) { |event| result4 = [:b, event.data] }
        client2.on_event(:b) { |event| result5 = [:b, event.data] }
        client3.on_event(:b) { |event| result6 = [:b, event.data] }

        $receive_count = 0

        $test = proc {
          result1.must_equal [:a, "data"]
          result2.must_equal [:a, "data"]
          result3.must_be_nil
          result4.must_be_nil
          result5.must_be_nil
          result6.must_be_nil
          EM.stop
        }

        def client1.notify!
          super
          $receive_count += 1
          if $receive_count == 3
            $test.call
          end
        end

        def client2.notify!
          super
          $receive_count += 1
          if $receive_count == 3
            $test.call
          end
        end

        def client3.notify!
          super
          $receive_count += 1
          if $receive_count == 3
            $test.call
          end
        end

        Thread.new {
          Simultaneous::Server.run(command)
        }.join
      }
    end
  end

  describe "Task" do
    it "should make it intact from client to process" do
      Simultaneous.domain = "example.org"
      Simultaneous.connection = SOCKET

      default_params = { :param1 => "param1" }
      env = { "ENV_PARAM" => "envparam" }
      args = {:param2 => "param2"}
      niceness = 10
      task_uid = 9999
      options = {
        :nice => niceness
      }
      task = Simultaneous.add_task(:publish, "/path/to/binary", options, default_params, env)
      command = Simultaneous::Command::Fire.new(task, args)
      dump = command.dump
      mock(command).dump { dump }
      mock(Simultaneous::Command::Fire).new(task, args) { command }
      mock(Simultaneous::Command).load(is_a(String)) { command }
      mock(command).valid? { true }
      mock(command).task_uid.twice { task_uid }

      EM.run do
        Simultaneous::Server.start(SOCKET)

        mock(Process).detach(9999)

        mock(command).fork do |block|
          mock(command).daemonize(%[/path/to/binary --param1="param1" --param2="param2"], is_a(String))
          mock(Process).setpriority(Process::PRIO_PROCESS, 0, niceness)
          mock(Process::UID).change_privilege(task_uid)
          mock(File).umask(0022)
          mock(command).exec(%[/path/to/binary --param1="param1" --param2="param2"])
          block.call

          ENV["ENV_PARAM"].must_equal "envparam"
          ENV[Simultaneous::ENV_DOMAIN].must_equal "example.org"
          ENV[Simultaneous::ENV_TASK_NAME].must_equal "publish"
          ENV[Simultaneous::ENV_CONNECTION].must_equal SOCKET
          EM.stop
          9999
        end

        Thread.new do
          Simultaneous.fire(:publish, args)
        end.join
      end
    end

    it "should report back to the server to set the task PID" do
      pids = {}
      pid = 99999
      Simultaneous.domain = "example.com"
      Simultaneous.connection = SOCKET


      EM.run do
        Simultaneous::Server.start(SOCKET)

        ENV[Simultaneous::ENV_DOMAIN] = "example.com"
        ENV[Simultaneous::ENV_TASK_NAME] = "publish"
        ENV[Simultaneous::ENV_CONNECTION] = SOCKET

        mock(Simultaneous::Task).pid { pid }
        mock(Simultaneous::Server).pids { pids }
        mock(pids).[]=("example.com/publish", pid) { EM.stop }

        Thread.new do
          class SimultaneousTask
            include Simultaneous::Task
          end
        end.join
      end
    end

    it "should be able to trigger messages on the client" do
      Simultaneous.domain = "example2.com"
      Simultaneous.connection = SOCKET


      EM.run do
        Simultaneous::Server.start(SOCKET)

        ENV[Simultaneous::ENV_DOMAIN] = "example2.com"
        ENV[Simultaneous::ENV_TASK_NAME] = "publish"
        ENV[Simultaneous::ENV_CONNECTION] = SOCKET

        c = Simultaneous::TaskClient.new("example2.com", SOCKET)
        mock(Simultaneous::TaskClient).new { c }
        mock(c).run(is_a(Simultaneous::Command::SetPid))
        proxy(c).run(is_a(Simultaneous::Command::ClientEvent))
        client = Simultaneous::Client.new("example2.com", SOCKET)

        client.on_event("publish_status") { |event|
          event.data.must_equal "completed"
          EM.stop
        }

        Thread.new do
          class SimultaneousTask
            include Simultaneous::Task
            def run
              simultaneous_event("publish_status", "completed")
            end
          end
          SimultaneousTask.new.run
        end.join

      end
    end

    it "should be able to kill task processes" do
      pid = 99999
      pids = {"example3.com/publish" => pid}
      Simultaneous.domain = "example3.com"
      Simultaneous.connection = SOCKET


      EM.run do
        Simultaneous::Server.start(SOCKET)

        ENV[Simultaneous::ENV_DOMAIN] = "example3.com"
        ENV[Simultaneous::ENV_TASK_NAME] = "publish"
        ENV[Simultaneous::ENV_CONNECTION] = SOCKET

        c = Simultaneous::TaskClient.new("example3.com", SOCKET)
        mock(Simultaneous::TaskClient).new { c }
        mock(c).run(is_a(Simultaneous::Command::SetPid))
        proxy(c).run(is_a(Simultaneous::Command::Kill))

        mock(Simultaneous::Task).pid { pid }
        mock(Simultaneous::Server).pids { pids }

        Thread.new do
          class SimultaneousTask
            include Simultaneous::Task
          end
        end.join

        Thread.new do
          mock(Process).kill("TERM", pid) { EM.stop }
          Simultaneous.kill(:publish)
        end.join
      end
    end

    it "should divert STDOUT and STDERR to file and inform the server when finished" do
      Simultaneous.domain = "example4.com"
      Simultaneous.connection = SOCKET
      logfile = "/tmp/log-#{$$}/#{$$}-example.log"
      FileUtils.rm_f(logfile) if File.exists?(logfile)
      EM.run do
        Simultaneous::Server.start(SOCKET)
        task = Simultaneous.add_task(:example, File.expand_path("../tasks/example.rb", __FILE__), {:logfile => logfile})
        proxy(Simultaneous::Server).run(is_a(Simultaneous::Command::Fire))
        mock(Simultaneous::Server).run(is_a(Simultaneous::Command::SetPid))
        mock(Simultaneous::Server).run(is_a(Simultaneous::Command::ClientEvent))
        mock(Simultaneous::Server).run(is_a(Simultaneous::Command::TaskComplete)) { EM.stop }
        Simultaneous.fire(:example, { "param" => "value" })
      end
      assert(File.exist?(logfile), "Task should have output to #{logfile}")
      File.read(logfile).must_equal %(--param=value\n)
      FileUtils.rm_rf(File.dirname(logfile)) if File.exists?(logfile)
    end
  end
end
