# encoding: UTF-8

require 'fileutils'

module Simultaneous
  module Command
    class Fire < CommandBase
      attr_reader :task_uid, :task_gid

      def initialize(task, params={})
        super
        @task_uid = Process.euid
        @task_gid = Process.egid
      end

      def niceness
        @task.niceness
      end

      def binary
        @task.binary
      end

      def binary_file
        @task.binary.split(" ").first
      end

      def cmd
        %(#{binary} #{Simultaneous.to_arguments(@params)})
      end

      def valid?
        exists? && permitted?
      end

      def permitted?
        raise PermissionsError, "'#{binary_file}' does not belong to user '#{ENV["USER"]}'" unless File.stat(binary_file).uid == task_uid
        true
      end

      def exists?
        raise FileNotFoundError, "'#{binary_file}'" unless File.exists?(binary_file)
        true
      end

      def env
        @task.env.merge({
          Simultaneous::ENV_CONNECTION => Simultaneous.connection,
          Simultaneous::ENV_TASK_NAME => task_name,
          Simultaneous::ENV_DOMAIN => domain
        })
      end

      def run
        if valid?
          pid = fork do
            ## set up the environment so that the task can access the F&F server
            env.each { | k, v | ENV[k] = v }
            ## TODO: figure out how to pass a logfile path to this
            daemonize(cmd, @task.logfile)
            Process.setpriority(Process::PRIO_PROCESS, 0, niceness) if niceness > 0
            ## change to the UID & GID of the originating thread if necessary
            Process::GID.change_privilege(task_gid) unless Process.egid == task_gid
            Process::UID.change_privilege(task_uid) unless Process.euid == task_uid
            File.umask(0022)
            Dir.chdir(@task.pwd)
            exec(cmd)
          end
          Process.detach(pid) if pid
          # don't return the PID as it's actually wrong (the daemonize call forks again so our original
          # PID is at least 1 out)
          "OK"
        end
      end

      def debug
        "Fire :#{namespaced_task_name}: #{cmd}\n"
      end

      private

      # The following adapted from Daemons.daemonize
      def daemonize(app_name = nil, logfile_name = nil)
        srand # Split rand streams between spawning and daemonized process
          safefork and exit # Fork and exit from the parent

        # Detach from the controlling terminal
        unless sess_id = Process.setsid
          raise RuntimeException.new('cannot detach from controlling terminal')
        end

        # Prevent the possibility of acquiring a controlling terminal
        trap 'SIGHUP', 'IGNORE'
        exit if pid = safefork

        $0 = app_name if app_name

        Dir.chdir "/"   # Release old working directory
        File.umask 0000 # Ensure sensible umask

        # Make sure all file descriptors are closed
        ObjectSpace.each_object(IO) do |io|
          unless [STDIN, STDOUT, STDERR].include?(io)
            begin
              unless io.closed?
                io.close
              end
            rescue ::Exception
            end
          end
        end

        redirect_io(logfile_name)

        return sess_id
      end

      def redirect_io(logfile_name)
        begin; STDIN.reopen "/dev/null"; rescue ::Exception; end

        if logfile_name
          FileUtils.mkdir_p(File.dirname(logfile_name))
          begin
            STDOUT.reopen logfile_name, "a"
            File.chmod(0644, logfile_name)
            STDOUT.sync = true
          rescue ::Exception
            begin; STDOUT.reopen "/dev/null"; rescue ::Exception; end
          end
        else
          begin; STDOUT.reopen "/dev/null"; rescue ::Exception; end
        end

        begin; STDERR.reopen STDOUT; rescue ::Exception; end
        STDERR.sync = true
      end

      def safefork
        tryagain = true

        while tryagain
          tryagain = false
          begin
            if pid = fork
              return pid
            end
          rescue Errno::EWOULDBLOCK
            sleep 5
            tryagain = true
          end
        end
      end

    end
  end
end
