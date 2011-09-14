# encoding: UTF-8

module FireAndForget
  module Command
    class SetStatus < CommandBase

      def initialize(task_name, status_value)
        @task_name, @status_value = task_name.to_sym, status_value
        @pid = $$
      end

      def run
        FireAndForget::Server.set_pid(namespaced_task_name, @pid)
        FireAndForget::Server.status[namespaced_task_name] = @status_value.to_s
      end

      def debug
        "SetStatus :#{namespaced_task_name}: #{@status_value}\n"
      end
    end
  end
end
