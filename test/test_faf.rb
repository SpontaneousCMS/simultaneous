require File.expand_path('../helper', __FILE__)

describe Simultaneous do
  it "should translate a hash to command line arguments" do
    Simultaneous.to_arguments({
      :param1 => "value1",
      :param2 => "value2",
      :array => [1, 2, "3 of 4"],
      :hash  => {:name => "Fred", :age => 23}
    }).must_equal %(--array=1 2 "3 of 4" --hash=name:"Fred" age:23 --param1="value1" --param2="value2")
  end
  it "should enable mapping of task to a binary" do
    Simultaneous.add_task(:publish, "/path/to/binary")
    Simultaneous.binary(:publish).must_equal  "/path/to/binary"
    Simultaneous[:publish].binary.must_equal  "/path/to/binary"
  end

  it "should enable setting of a niceness value for the task" do
    Simultaneous.add_task(:publish1, "/path/to/binary", {:niceness => 10})
    Simultaneous[:publish1].niceness.must_equal  10
    Simultaneous.add_task(:publish2, "/path/to/binary", {:nice => 12})
    Simultaneous[:publish2].niceness.must_equal  12
  end


  it "should enable launching a task by its name" do
    Simultaneous.add_task(:publish, "/path/to/binary")
    args = {:param1 => "param1", :param2 => "param2"}
    mock(Simultaneous).fire(:publish, args)
    Simultaneous.publish(args)
  end

  it "should enable setting of path to socket" do
    Simultaneous.connection = "/tmp/something"
    Simultaneous.connection.must_equal  "/tmp/something"
  end

  it "should enable setting of domain" do
    Simultaneous.domain = "domain_name"
    Simultaneous.domain.must_equal  "domain_name"
  end

end
