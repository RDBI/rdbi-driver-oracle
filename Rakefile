require 'rubygems'
require 'rake'

begin

  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = "rdbi-driver-oracle"
    gem.summary = %Q{Oracle driver for RDBI}
    gem.description = %Q{Oracle driver for RDBI}
    gem.email = ""
    gem.homepage = "https://github.com/RDBI/rdbi-driver-oracle.git"
    gem.authors = [ "Pilcrow" ]
    gem.version = "0.0.1"

    gem.add_development_dependency 'test-unit'
    gem.add_development_dependency 'rdoc'

    gem.add_dependency 'rdbi'
    gem.add_dependency 'ruby-oci8'

  end

  Jeweler::GemcutterTasks.new

rescue LoadError

  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"

  # Define this task if Jeweler is not available.
  task :check_dependencies

end

require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin

  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end

rescue LoadError

  task :rcov do
    abort "RCov is not available."
  end

end

task :test => :check_dependencies

task :default =>  :test

