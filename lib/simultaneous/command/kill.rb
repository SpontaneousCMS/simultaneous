# encoding: UTF-8

module Simultaneous
  module Command
    class Kill < CommandBase

      def initialize(task_name, signal="TERM")
        @task_name, @signal = task_name.to_sym, signal
      end

      def run
        Simultaneous::Server.kill(namespaced_task_name, @signal)
      end
      def debug
        "Kill :#{namespaced_task_name}: #{@signal}\n"
      end
    end
  end
end
