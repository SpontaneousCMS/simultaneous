require File.expand_path('../helper', __FILE__)

describe Simultaneous::TaskDescription do
  it "should generate the right default logfile location" do
    mock(Dir).pwd.times(any_times) { "/application/current" }
    task = Simultaneous::TaskDescription.new(:fish, "/path/to/fish")
    task.logfile.must_equal "/application/current/log/fish-task.log"
  end

  it "should generate the right default logfile relative to the configured pwd" do
    # mock(Dir).pwd { "/application/current" }
    task = Simultaneous::TaskDescription.new(:fish, "/path/to/fish", {:pwd => "/application/home", :log => "log/task.log"})
    task.logfile.must_equal "/application/home/log/task.log"
  end

  it "should use the configured logfile location" do
    task = Simultaneous::TaskDescription.new(:fish, "/path/to/fish", {:logfile => "/var/log/fish.log"})
    task.logfile.must_equal "/var/log/fish.log"
  end

  it "should use the configured log location" do
    task = Simultaneous::TaskDescription.new(:fish, "/path/to/fish", {:log => "/var/log/fish.log"})
    task.logfile.must_equal "/var/log/fish.log"
  end

  it "should set the right pwd" do
    task = Simultaneous::TaskDescription.new(:fish, "/path/to/fish", {:pwd => "/application/home", :log => "log/task.log"})
    task.pwd.must_equal "/application/home"
  end
end
