# encoding: UTF-8

require 'socket'
require 'eventmachine'

module Simultaneous
  VERSION = "0.3.1"

  DEFAULT_CONNECTION = "/tmp/simultaneous-server.sock"
  DEFAULT_PORT = 9999
  DEFAULT_HOST = 'localhost'

  ENV_CONNECTION = "SIMULTANEOUS_CONNECTION"
  ENV_DOMAIN = "SIMULTANEOUS_DOMAIN"
  ENV_TASK_NAME = "SIMULTANEOUS_TASK_NAME"

  class Error < ::StandardError; end
  class PermissionsError < Error; end
  class FileNotFoundError < Error; end

  module ClassMethods

    def server_binary
      File.expand_path("../../bin/simultaneous-server", __FILE__)
    end

    # Registers a task and makes it available for easy launching using #fire
    #
    # @param [Symbol] task_name
    #   the name for the task. This should be unique
    #
    # @param [String] path_to_binary
    #   the path to the executable that should be run when this task is launched
    #
    # @param [Hash] options
    #   A hash of options for the task. Available options are:
    #     :niceness: the niceness value of the process, >=0
    #     :logfile:  the location of the processes log file to which all io will be redirected
    #     :pwd:      directory that the task should work in
    #
    # @param [Fixnum] niceness
    #   the niceness value of the process >= 0. The higher this value the 'nicer' the launched
    #   process will be (a high nice value results in a low priority task).
    #   On UNIX systems the max, nicest, value is 20
    #
    # @param [Hash] default_params
    #   A Hash of parameters that should be passed to every invocation of the task.
    #   These will be converted to command line parameters
    #     { "setting" => "value", "output" => "destination"}
    #   gives the parameters
    #     --setting=value --output=destination
    #   @see Simultaneous::Utilities#to_arguments
    #
    # @param [Hash] env
    #   A Hash of values to add to the task's ENV settings
    #
    def add_task(task_name, path_to_binary, options={}, default_params={}, env={})
      tasks[task_name] = TaskDescription.new(task_name, path_to_binary, options, default_params, env)
    end

    # Launches the given task
    #
    # @param [Symbol] task_name the name of the task to launch
    # @param [Hash] params parameters to pass to the executable
    def fire(task_name, params={})
      task = tasks[task_name]
      command = Command::Fire.new(task, params)
      client.run(command)
    end

    def client=(client)
      @client.close if @client
      @client = client
    end

    def client
      @client ||= \
        begin
          client = \
            if ::EM.reactor_running?
              Client.new(domain, connection)
            else
              TaskClient.new(domain, connection)
            end
          # make sure that new client is hooked into all listeners
          event_listeners.each do |event, blocks|
            blocks.each do |block|
              client.on_event(event, &block)
            end
          end
          client
        end
    end

    def event_listeners
      @event_listeners ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def on_event(event, &block)
      event_listeners[event] << block
      client.on_event(event, &block) if client
    end

    def reset_client!
      @client = nil
    end

    def reset!
      reset_client!
      @tasks = nil
    end

    # Returns the path to the binary for the given task
    #
    # @param [Symbol] task_name the name of the task
    # @return [String] the path of the task's binary
    def binary(task_name)
      tasks[task_name].binary
    end

    # Gets the TaskDescription of a task
    #
    # @param [Symbol] task_name the name of the task to get
    def [](task_name)
      tasks[task_name]
    end

    def tasks
      @tasks ||= {}
    end

    def connection=(connection)
      reset_client!
      @connection = connection
    end

    def domain=(domain)
      reset_client!
      @domain = domain
    end

    def connection
      @connection ||= (ENV[Simultaneous::ENV_CONNECTION] || Simultaneous::DEFAULT_CONNECTION)
    end

    def domain
      @domain ||= (ENV[Simultaneous::ENV_DOMAIN] || "domain#{$$}")
    end

    # Used by the {Simultaneous::Daemon} module to set the correct PID for a given task
    def map_pid(task_name, pid)
      command = Command::SetPid.new(task_name, pid)
      client.run(command)
    end

    alias_method :set_pid, :map_pid

    def send_event(event, data)
      command = Command::ClientEvent.new(domain, event, data)
      client.run(command)
    end

    # Sends a running task the TERM signal
    def term(task_name)
      kill(task_name, "TERM")
    end

    # Sends a running task the INT signal
    def int(task_name)
      kill(task_name, "INT")
    end

    # Sends a running task an arbitrary signal
    #
    # @param [Symbol] task_name the name of the task to send the signal
    # @param [String] signal the signal to send
    #
    # @see Signal#list for a full list of signals available
    def kill(task_name, signal="TERM")
      command = Command::Kill.new(task_name, signal)
      client.run(command)
    end

    def task_complete(task_name)
      command = Command::TaskComplete.new(task_name)
      client.run(command)
    end

    def to_arguments(params={})
      params.keys.sort { |a, b| a.to_s <=> b.to_s }.map do |key|
        %(--#{key}=#{to_parameter(params[key])})
      end.join(" ")
    end

    # Maps objects to command line parameters suitable for parsing by Thor
    # @see https://github.com/wycats/thor
    def to_parameter(obj)
      case obj
      when String
        obj.inspect
      when Array
        obj.map { |o| to_parameter(o) }.join(' ')
      when Hash
        obj.map do |k, v|
          "#{k}:#{to_parameter(obj[k])}"
        end.join(' ')
      when Numeric
        obj
      else
        to_parameter(obj.to_s)
      end
    end

    TCP_CONNECTION_MATCH = %r{^([^/]+):(\d+)}
    # Convert connection string into an argument array suitable for passing
    # to EM.connect or EM.server
    # e.g.
    #   "/path/to/socket.sock" #=> ["/path/to/socket.sock"]
    #   "localhost:9999" #=> ["localhost", 9999]
    #
    def parse_connection(connection_string)
      if connection_string =~ TCP_CONNECTION_MATCH
        [$1, $2.to_i]
      else
        [connection_string]
      end
    end

    def client_connection(connection_string)
      if connection_string =~ TCP_CONNECTION_MATCH
        TCPSocket.new($1, $2.to_i)
      else
        UNIXSocket.new(connection_string)
      end
    end

    protected

    # Catch method missing to enable launching of tasks by direct name
    # e.g.
    #   Simultaneous.add_task(:process_things, "/usr/bin/process")
    # launch this task:
    #   Simultaneous.process_things
    #
    def method_missing(method, *args, &block)
      if tasks.key?(method)
        fire(method, *args, &block)
      else
        super
      end
    end
  end

  extend ClassMethods

  autoload :Connection,       "simultaneous/connection"
  autoload :Server,           "simultaneous/server"
  autoload :Client,           "simultaneous/client"
  autoload :TaskClient,       "simultaneous/task_client"
  autoload :Task,             "simultaneous/task"
  autoload :TaskDescription,  "simultaneous/task_description"
  autoload :BroadcastMessage, "simultaneous/broadcast_message"
  autoload :Command,          "simultaneous/command"
  autoload :Rack,             "simultaneous/rack"
end
