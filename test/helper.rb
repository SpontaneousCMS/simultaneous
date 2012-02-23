path = File.expand_path('../../lib', __FILE__)
$:.unshift(path) if File.directory?(path) && !$:.include?(path)

require 'minitest/spec'
require 'minitest/autorun'
require 'rr'
require 'fileutils'
require File.expand_path('../../lib/simultaneous', __FILE__)


$debug = false

SOCKET = "/tmp/#{$$}-faf.socket"

class MiniTest::Spec
  include RR::Adapters::MiniTest
end
