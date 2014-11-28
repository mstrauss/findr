require 'rake/rspec'

task :default => [:test, :spec]

task :test do
  fail("Command failed.") unless system("bin/findr -g '*.rb' VERSION")
end
