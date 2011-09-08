# encoding: UTF-8

module FireAndForget
  module Command
    SEPARATOR = "||".freeze

    def self.load(command)
      Marshal.load(command)
    end

    def self.allowed?(cmd)
      allowed_commands.include?(cmd.class)
    end

    def self.allowed_commands
      @allowed_commands ||= self.constants.map { |c| self.const_get(c) }.select do |k|
        k.respond_to?(:ancestors) && k.ancestors.include?(CommandBase)
      end
    end

    class CommandBase
      attr_reader :tag, :cmd, :params, :task

      def initialize(task, params={})
        @task, @params = task, merge_params(task.params, params)
      end

      def dump
        Marshal.dump(self)
      end

      def run
        # overridden in subclasses
      end


      def merge_params(task_params, call_params)
        params = task_params.to_a.inject({}) do |hash, (key, value)|
          hash[key.to_s] = value; hash
        end
        call_params.each do |key, value|
          params[key.to_s] = value
        end if call_params
        params
      end

      def debug()
        "#{self.class.name.split("::").last} :#{@task_name}\n"
      end
    end

    autoload :Fire, "faf/command/fire"
    autoload :Kill, "faf/command/kill"
    autoload :SetStatus, "faf/command/set_status"
    autoload :GetStatus, "faf/command/get_status"
    autoload :SetPid, "faf/command/set_pid"
    autoload :GetPid, "faf/command/get_pid"
  end
end
