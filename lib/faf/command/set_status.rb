# encoding: UTF-8

module FireAndForget
  module Command
    class SetStatus < CommandBase

      def initialize(task_name, status_value)
        @task_name, @status_value = task_name.to_sym, status_value
        @pid = $$
      end

      def run
        FireAndForget::Server.set_pid(@task_name, @pid)
        FireAndForget::Server.status[@task_name] = @status_value.to_s
      end

      def debug
        "SetStatus :#{@task_name}: #{@status_value}\n"
      end
    end
  end
end
