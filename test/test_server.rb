require File.expand_path('../helper', __FILE__)

describe FireAndForget::Server do
  before do
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
        FAF::Server.start(SOCKET)

        client1 = FAF::Client.new("domain1", SOCKET)
        client2 = FAF::Client.new("domain1", SOCKET)
        client3 = FAF::Client.new("domain2", SOCKET)

        command = FAF::Command::ClientEvent.new("domain1", "a", "data")

        client1.subscribe(:a) { |data| result1 = [:a, data] }
        client2.subscribe(:a) { |data| result2 = [:a, data] }
        client3.subscribe(:a) { |data| result3 = [:a, data] }
        client1.subscribe(:b) { |data| result4 = [:b, data] }
        client2.subscribe(:b) { |data| result5 = [:b, data] }
        client3.subscribe(:b) { |data| result6 = [:b, data] }

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
          FAF::Server.run(command)
        }.join
      }
    end
  end
  describe "Task" do
    it "should make it intact from client to process" do
      default_params = { :param1 => "param1" }
      env = { "ENV_PARAM" => "envparam" }
      args = {:param2 => "param2"}
      niceness = 10
      task_uid = 9999
      task = FAF.add_task(:publish, "/path/to/binary", niceness, default_params, env)
      command = FAF::Command::Fire.new(task, args)
      dump = command.dump
      mock(command).dump { dump }
      mock(FAF::Command::Fire).new(task, args) { command }
      mock(FAF::Command).load(is_a(String)) { command }
      mock(command).valid? { true }
      mock(command).task_uid.twice { task_uid }
      FAF.domain = "example.org"
      FAF.socket = SOCKET

      EM.run do
        FAF::Server.start(SOCKET)

        mock(Process).detach(9999)

        mock(command).fork do |block|
          mock(command).daemonize
          mock(Process).setpriority(Process::PRIO_PROCESS, 0, niceness)
          mock(Process::UID).change_privilege(task_uid)
          mock(File).umask(0022)
          mock(command).exec(%[/path/to/binary --param1="param1" --param2="param2"])
          block.call

          ENV["ENV_PARAM"].must_equal "envparam"
          ENV[FAF::ENV_DOMAIN].must_equal "example.org"
          ENV[FAF::ENV_TASK_NAME].must_equal "publish"
          ENV[FAF::ENV_SOCKET].must_equal SOCKET
          EM.stop
          9999
        end

        Thread.new do
          FAF.fire(:publish, args)
        end.join
      end
    end

    it "should be able to trigger messages on the client" do
      FAF.domain = "example.com"
      FAF.socket = SOCKET
      pids = {}


      EM.run do
        FAF::Server.start(SOCKET)

        ENV[FAF::ENV_DOMAIN] = "example.com"
        ENV[FAF::ENV_TASK_NAME] = "publish"
        ENV[FAF::ENV_SOCKET] = SOCKET
        Thread.new do
          mock(FAF.client).run(is_a(FAF::Command::SetPid))
          proxy(FAF.client).run(is_a(FAF::Command::ClientEvent))
          # mock(FireAndForget::Server).pids { pids }
          # mock(pids).[]=(:"publish", $$)
          client = FAF::Client.new("example.com", SOCKET)
          p client

          client.subscribe(:publish_status) { |data|
            puts "*"*50
            data.must_equal "completed"
            EM.stop
          }
        end.join

        Thread.new do
          class FAFTask
            include FAF::Task
            def run
              faf_event("publish_status", "completed")
            end
          end
          FAFTask.new.run
        end.join

      end
    end
  end
end
