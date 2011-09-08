# encoding: UTF-8

module FireAndForget
  class TaskDescription
    attr_reader :name, :binary, :niceness, :params, :env

    def initialize(name, path_to_binary, niceness=0, default_parameters={}, env={})
      @name, @binary, @params, @niceness, @env = name, path_to_binary, default_parameters, niceness, env
    end
  end
end
