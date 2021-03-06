## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'simultaneous'
  s.version           = '0.5.2'
  s.date              = '2016-05-17'
  s.rubyforge_project = 'simultaneous'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Simultaneous is the background task launcher used by Spontaneous CMS"
  s.description = "Simultaneous is designed for the very specific use case of a small set of users collaborating on editing a single website. Because of that it is optimised for infrequent invocation of very long running publishing tasks and provides an event based messaging system that allows launched tasks to communicate back to the CMS web-server and for that server to then fire off update messages through HTML5 Server-Sent Events."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Garry Hill"]
  s.email    = 'garry@magnetised.info'
  s.homepage = 'http://spontaneouscms.org'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## If your gem includes any executables, list them here.
  s.executables = ["simultaneous-server", "simultaneous-console"]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README LICENSE]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('eventmachine', [">= 1.0.0.rc.1", "< 2.0"])
  s.add_dependency('rack', [">= 1.0", "< 2.0"])
  s.add_dependency('async-rack', ["~> 0.5.0"])

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('rr', ["~> 1.0.4"])

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README
    Rakefile
    bin/simultaneous-console
    bin/simultaneous-server
    lib/simultaneous.rb
    lib/simultaneous/async_client.rb
    lib/simultaneous/broadcast_message.rb
    lib/simultaneous/command.rb
    lib/simultaneous/command/client_event.rb
    lib/simultaneous/command/fire.rb
    lib/simultaneous/command/kill.rb
    lib/simultaneous/command/set_pid.rb
    lib/simultaneous/command/task_complete.rb
    lib/simultaneous/connection.rb
    lib/simultaneous/rack.rb
    lib/simultaneous/server.rb
    lib/simultaneous/sync_client.rb
    lib/simultaneous/task.rb
    lib/simultaneous/task_description.rb
    simultaneous.gemspec
    test/helper.rb
    test/tasks/example.rb
    test/test_client.rb
    test/test_command.rb
    test/test_connection.rb
    test/test_faf.rb
    test/test_message.rb
    test/test_server.rb
    test/test_task.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
