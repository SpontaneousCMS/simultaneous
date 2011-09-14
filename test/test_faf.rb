require File.expand_path('../helper', __FILE__)

describe FireAndForget do
  it "should translate a hash to command line arguments" do
    FAF.to_arguments({
      :param1 => "value1",
      :param2 => "value2",
      :array => [1, 2, "3 of 4"],
      :hash  => {:name => "Fred", :age => 23}
    }).must_equal %(--array=1 2 "3 of 4" --hash=name:"Fred" age:23 --param1="value1" --param2="value2")
  end
  it "should enable mapping of task to a binary" do
    FAF.add_task(:publish, "/path/to/binary")
    FAF.binary(:publish).must_equal  "/path/to/binary"
    FAF[:publish].binary.must_equal  "/path/to/binary"
  end

  it "should enable setting of a niceness value for the task" do
    FAF.add_task(:publish, "/path/to/binary", 10)
    FAF[:publish].niceness.must_equal  10
  end


  it "should enable launching a task by its name" do
    FAF.add_task(:publish, "/path/to/binary")
    args = {:param1 => "param1", :param2 => "param2"}
    mock(FAF).fire(:publish, args)
    FAF.publish(args)
  end

  it "should enable setting of path to socket" do
    FAF.connection = "/tmp/something"
    FAF.connection.must_equal  "/tmp/something"
  end

  it "should enable setting of domain" do
    FAF.domain = "domain_name"
    FAF.domain.must_equal  "domain_name"
  end

  it "should be able to parse connection strings" do
    FAF.parse_connection("/path/to/socket.sock").must_equal ["/path/to/socket.sock"]
    FAF.parse_connection("socket.sock").must_equal ["socket.sock"]
    FAF.parse_connection("localhost:1234").must_equal ["localhost", 1234]
    FAF.parse_connection("127.0.0.1:9999").must_equal ["127.0.0.1", 9999]
    FAF.parse_connection("123.239.23.1:9999").must_equal ["123.239.23.1", 9999]
    FAF.parse_connection("host.domain.com:9999").must_equal ["host.domain.com", 9999]
  end
end
