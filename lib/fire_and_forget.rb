# encoding: UTF-8

require 'eventmachine'

module FireAndForget
  DEFAULT_SOCKET = "/tmp/faf.sock"
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 9999
end

FAF = FireAndForget

require 'faf/broadcast_message'
require 'faf/server'
require 'faf/client'
