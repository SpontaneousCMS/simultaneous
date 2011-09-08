# encoding: UTF-8

module FireAndForget
  module Command
    class GetPid < CommandBase

      attr_reader :task_name, :pid

      def initialize(task_name)
        @task_name = task_name.to_sym
      end

      def run
        FireAndForget::Server.pids[@task_name]
      end
    end
  end
end
