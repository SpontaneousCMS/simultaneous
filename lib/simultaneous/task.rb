module Simultaneous
  module Task

    def self.task_name
      ENV[Simultaneous::ENV_TASK_NAME]
    end

    def self.pid
      $$
    end

    def self.included(klass)
      Simultaneous.client = Simultaneous::SyncClient.new
      Simultaneous.set_pid(self.task_name, pid) if task_name
      at_exit {
        begin
          Simultaneous.task_complete(self.task_name)
        rescue Errno::ECONNREFUSED
        rescue Errno::ENOENT
        end

      # Simultaneous.client.close
      }
    rescue Errno::ECONNREFUSED
    rescue Errno::ENOENT
      # server isn't running but we don't want this to stop our script
    end


    def simultaneous_event(event, message)
      Simultaneous.send_event(event, message)
    rescue Errno::ECONNREFUSED
    rescue Errno::ENOENT
      # server isn't running but we don't want this to stop our script
    end
  end
end
