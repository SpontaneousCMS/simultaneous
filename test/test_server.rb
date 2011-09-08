require File.expand_path('../helper', __FILE__)

module AClient
  def connection_completed
    puts "CONNECTED"
  end
end
describe FireAndForget::Server do
  before do
  end

  describe "broadcasting messages" do
    it "should generate events in clients on the right channel" do
      client1 = client2 = client3 = nil
      result1 = result2 = result3 = nil
      result4 = result5 = result6 = nil

      # EM.run {
      #   EM.start_server("127.0.0.1", 9999)
      #   EM.connect("127.0.0.1", 9999, AClient)
      #   EM.connect("127.0.0.1", 9999, AClient)
      #   EM.connect("127.0.0.1", 9999, AClient)
      #   # EM.stop
      # }
      EM.run {
        FAF::Server.start_tcp()

        client1 = FAF::Client.tcp_client("channel1")
        client2 = FAF::Client.tcp_client("channel1")
        client3 = FAF::Client.tcp_client("channel2")

        message = FAF::BroadcastMessage.new({
          :channel => "channel1",
          :event => "a",
          :data => "data"
        })

        trace = proc {

        }
        client1.subscribe(:a) { |data| result1 = [:a, data] }
        client2.subscribe(:a) { |data| result2 = [:a, data] }
        client3.subscribe(:a) { |data| result3 = [:a, data] }
        client1.subscribe(:b) { |data| result4 = [:b, data] }
        client2.subscribe(:b) { |data| result5 = [:b, data] }
        client3.subscribe(:b) { |data| result6 = [:b, data] }

        Thread.new {
          result1 = result2 = result3 = nil
          FAF::Server.broadcast(message.to_src)
        }.join

        EM.next_tick { EM.next_tick { EM.next_tick {
          EM.next_tick { EM.next_tick { EM.next_tick {
          puts "#"*50
          result1.must_equal [:a, "data"]
          result2.must_equal [:a, "data"]
          result3.must_be_nil
          result4.must_be_nil
          result5.must_be_nil
          EM.stop
        }}}}}}

        result1 = result2 = result3 = nil
        message = FAF::BroadcastMessage.new({
          :channel => "channel2",
          :event => "b",
          :data => "data"
        })

        Thread.new {
          FAF::Server.broadcast(message.to_src)
          result1 = result2 = result3 = nil
        }.join
        EM.next_tick { EM.next_tick { EM.next_tick {
          EM.next_tick { EM.next_tick { EM.next_tick {
          puts "#"*50
          result4.must_be_nil
          result5.must_be_nil
          result6.must_equal [:b, "data"]
          EM.stop
        }}}}}}
      }
    end
  end
end
