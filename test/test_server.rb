require File.expand_path('../helper', __FILE__)

describe FireAndForget::Server do
  before do
  end
  after do
    FileUtils.rm(SOCKET) if File.exist?(SOCKET)
  end

  describe "broadcasting messages" do
    it "should generate events in clients on the right domain" do
      client1 = client2 = client3 = nil
      result1 = result2 = result3 = nil
      result4 = result5 = result6 = nil

      EM.run {
        FAF::Server.start(SOCKET)

        client1 = FAF::Client.new("domain1", SOCKET)
        client2 = FAF::Client.new("domain1", SOCKET)
        client3 = FAF::Client.new("domain2", SOCKET)

        message = FAF::BroadcastMessage.new({
          :domain => "domain1",
          :event => "a",
          :data => "data"
        })

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
          FAF::Server.broadcast(message.to_src)
        }.join

      }
    end
  end
end
