require File.expand_path('../helper', __FILE__)

describe Simultaneous::BroadcastMessage do

  it "should assign a unique id to each message" do
    message1 = Simultaneous::BroadcastMessage.new
    message2 = Simultaneous::BroadcastMessage.new
    message1.id.wont_equal message2.id
  end

  describe "when parsing input" do
    before do
      @message = Simultaneous::BroadcastMessage.new
    end
    it "should begin as invalid" do
      @message.valid?.wont_be :==, true
    end

    it "should recognise the domain: header" do
      @message << "domain: name"
      @message.domain.must_equal "name"
      @message.valid?.wont_be :==, true
    end

    it "should recognise the id: header" do
      @message << "id: 12345"
      @message.id.must_equal "12345"
      @message.valid?.wont_be :==, true
    end

    it "should recognise the event: header" do
      @message << "event: name"
      @message.event.must_equal "name"
      @message.valid?.wont_be :==, true
    end

    it "should recognise the data: header" do
      @message << "data: a"
      @message.data.must_equal "a"
      @message << "data: b"
      @message.data.must_equal "a\nb"
      @message << "data: c"
      @message.data.must_equal "a\nb\nc"
      @message.valid?.wont_be :==, true
    end

    it "should ignore comments" do
      @message << ": a"
      @message.data.must_equal ""
    end

    it "should ignore blank lines" do
      @message << ""
      @message.data.must_equal ""
    end
  end

  describe "when data has been parsed" do
    before do
      @message = Simultaneous::BroadcastMessage.new
      @message.id = "62936e70-1815-439b-bf89-8492855a7e6b"
      @message.event = "event"
      @message.domain = "domain"
      @message.data = "line 1\nline 2"
    end

    it "should be valid" do
      @message.valid?.must_equal true
    end

    it "should serialise to a SSE-friendly format" do
      @message.to_event.must_equal((<<-SRC).gsub(/^ */, ''))
        domain: domain
        event: event
        id: 62936e70-1815-439b-bf89-8492855a7e6b
        data: line 1
        data: line 2

      SRC
    end
  end

  describe "when initialising" do
    it "should accept values at initialisation" do
      message = Simultaneous::BroadcastMessage.new({
        :domain => "domain",
        :event => "event",
        :id => "62936e70-1815-439b-bf89-8492855a7e6b",
        :data => "line 1\nline 2"
      })
      message.domain.must_equal "domain"
      message.event.must_equal "event"
      message.data.must_equal "line 1\nline 2"
      message.id.must_equal "62936e70-1815-439b-bf89-8492855a7e6b"
    end
  end
end
