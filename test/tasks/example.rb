#!/usr/bin/env ruby

require 'rubygems'

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'fire_and_forget'

class MyTask
  include FAF::Task
  def run
    puts ARGV[0]
    # sleep(10)
    faf_event("example", "done")
    puts "DONE "*10
  end
end

MyTask.new.run
