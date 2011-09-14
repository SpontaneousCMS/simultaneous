module FireAndForget
  module Task

    def self.task_name
      ENV[FireAndForget::ENV_TASK_NAME]
    end

    def self.pid
      $$
    end

    def self.included(klass)
      FireAndForget.set_pid(self.task_name, pid)
    rescue Errno::ECONNREFUSED
      puts "Errno::ECONNREFUSED"
      # server isn't running but we don't want this to stop our script
    end


    def faf_event(event, message)
      FireAndForget.send_event(event, message)
    rescue Errno::ECONNREFUSED
      # server isn't running but we don't want this to stop our script
    end

    def set_task_status(status)
      FireAndForget.set_status(FireAndForget::Daemon.task_name, status)
    rescue Errno::ECONNREFUSED
      # server isn't running but we don't want this to stop our script
    end
  end
end
