#!/usr/bin/env ruby

require 'rubygems'

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'simultaneous'

class MyTask
  include Simultaneous::Task

  def run
    puts ARGV[0]
    # 10.times do |i|
    #   puts i
    #   sleep(1)
    # end
    simultaneous_event("example", "done")
  end
end

MyTask.new.run
