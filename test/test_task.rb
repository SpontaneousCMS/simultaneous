require File.expand_path('../helper', __FILE__)

describe FireAndForget::TaskDescription do
  it "should generate the right default logfile location" do
    mock(Dir).pwd { "/application/current" }
    task = FAF::TaskDescription.new(:fish, "/path/to/fish")
    task.logfile.must_equal "/application/current/log/fish-task.log"
  end
  it "should generate the right default logfile location" do
    task = FAF::TaskDescription.new(:fish, "/path/to/fish", {:logfile => "/var/log/fish.log"})
    task.logfile.must_equal "/var/log/fish.log"
  end
  it "should generate the right default logfile location" do
    task = FAF::TaskDescription.new(:fish, "/path/to/fish", {:log => "/var/log/fish.log"})
    task.logfile.must_equal "/var/log/fish.log"
  end
end