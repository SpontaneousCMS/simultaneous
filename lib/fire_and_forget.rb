# encoding: UTF-8

require 'eventmachine'

module FireAndForget
  DEFAULT_SOCKET = "/tmp/faf.sock"
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 9999

  ENV_SOCKET = "__FAF_SOCKET"
  ENV_DOMAIN = "__FAF_DOMAIN"
  ENV_TASK_NAME = "__FAF_TASK_NAME"

  class Error < ::StandardError; end
  class PermissionsError < Error; end
  class FileNotFoundError < Error; end

  module ClassMethods
    # Registers a task and makes it available for easy launching using #fire
    #
    # @param [Symbol] task_name
    #   the name for the task. This should be unique
    #
    # @param [String] path_to_binary
    #   the path to the executable that should be run when this task is launched
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
    #   @see FireAndForget::Utilities#to_arguments
    #
    # @param [Hash] env
    #   A Hash of values to add to the task's ENV settings
    #
    def add_task(task_name, path_to_binary, niceness=0, default_params={}, env={})
      tasks[task_name] = TaskDescription.new(task_name, path_to_binary, niceness, default_params, env)
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

    def client
      @client ||= Client.new(domain, socket)
    end

    def reset_client!
      @client = nil
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

    def socket=(socket)
      reset_client!
      @socket = socket
    end

    def domain=(domain)
      reset_client!
      @domain = domain
    end

    def socket
      @socket ||= (ENV[FireAndForget::ENV_SOCKET] || FireAndForget::DEFAULT_SOCKET)
    end

    def domain
      @domain ||= (ENV[FireAndForget::ENV_DOMAIN] || "domain#{$$}")
    end

    # Used by the {FireAndForget::Daemon} module to set the correct PID for a given task
    def map_pid(task_name, pid)
      command = Command::SetPid.new(task_name, pid)
      client.run(command)
    end
    alias_method :set_pid, :map_pid

    def send_event(event, data)
      command = Command::ClientEvent.new(domain, event, data)
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

    protected

    # Catch method missing to enable launching of tasks by direct name
    # e.g.
    #   FireAndForget.add_task(:process_things, "/usr/bin/process")
    # launch this task:
    #   FireAndForget.process_things
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
end

FAF = FireAndForget unless defined?(FAF)

require 'faf/broadcast_message'
require 'faf/server'
require 'faf/client'
require 'faf/task'
require 'faf/task_description'
require 'faf/command'
