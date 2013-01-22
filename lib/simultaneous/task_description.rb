# encoding: UTF-8

module Simultaneous
  class TaskDescription
    attr_reader :name, :binary, :options, :params, :env

    # options:
    #   :nice
    #   :logfile - defaults to PWD/log/task_name.log
    #   :pwd     - the directory that the task should run in
    #
    #
    # name, path_to_binary, options, default_parameters, env
    def initialize(name, path_to_binary, options={}, default_parameters={}, env={})
      @name, @binary, @params, @options, @env = name, path_to_binary, default_parameters, options, env
    end

    def niceness
      (options[:nice] || options[:niceness] || 0)
    end

    def logfile
      File.expand_path(options[:logfile] || options[:log] || default_log_file, pwd)
    end

    def pwd
      (options[:pwd] || default_pwd)
    end

    def default_log_file
      File.join(pwd, "log", "#{name}-task.log")
    end

    def default_pwd
      Dir.pwd
    end
  end
end

