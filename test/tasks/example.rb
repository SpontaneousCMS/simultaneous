#!/usr/bin/env ruby

require 'rubygems'

$:.unshift(File.expand_path("../../../lib", __FILE__))

require 'fire_and_forget'

class MyTask
  include FAF::Task

  def run
    puts ARGV[0]
    faf_event("example", "done")
  end
end

MyTask.new.run
