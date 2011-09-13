require 'minitest/spec'
require 'minitest/autorun'
require 'rr'
require 'fire_and_forget'
require 'fileutils'


$debug = false

SOCKET = "/tmp/#{$$}-faf.socket"

class MiniTest::Spec
  include RR::Adapters::MiniTest
end
