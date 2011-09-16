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
    FAF.add_task(:publish1, "/path/to/binary", {:niceness => 10})
    FAF[:publish1].niceness.must_equal  10
    FAF.add_task(:publish2, "/path/to/binary", {:nice => 12})
    FAF[:publish2].niceness.must_equal  12
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

end
