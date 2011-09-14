# encoding: UTF-8

module FireAndForget
  module Command
    class GetStatus < CommandBase

      def initialize(task_name)
        @task_name = task_name.to_sym
      end

      def run
        FireAndForget::Server.status[namespaced_task_name]
      end
    end
  end
end
