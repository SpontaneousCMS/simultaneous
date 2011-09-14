module FireAndForget
  module Task

    def self.task_name
      ENV[FireAndForget::ENV_TASK_NAME]
    end

    def self.pid
      $$
    end

    def self.included(klass)
      FAF.client = FAF::TaskClient.new
      FireAndForget.set_pid(self.task_name, pid) if task_name
      at_exit {
        begin
          FireAndForget.task_complete(self.task_name)
        rescue Errno::ECONNREFUSED
        rescue Errno::ENOENT
        end

      # FireAndForget.client.close
      }
    rescue Errno::ECONNREFUSED
    rescue Errno::ENOENT
      # server isn't running but we don't want this to stop our script
    end


    def faf_event(event, message)
      FireAndForget.send_event(event, message)
    rescue Errno::ECONNREFUSED
    rescue Errno::ENOENT
      # server isn't running but we don't want this to stop our script
    end
  end
end
