# encoding: UTF-8

module Simultaneous
  module Command
    class TaskComplete < CommandBase
      def initialize(task_name)
        @task_name = task_name
      end

      def run
        Simultaneous::Server.task_complete(namespaced_task_name)
      end
      def debug
        "TaskComplete :#{namespaced_task_name}\n"
      end
    end
  end
end
