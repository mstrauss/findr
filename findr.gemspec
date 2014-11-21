
# -*- encoding: utf-8 -*-
$:.push('lib')
require "findr/version"

Gem::Specification.new do |s|
  s.name     = "findr"
  s.version  = Findr::VERSION.dup
  s.date     = "2012-06-01"
  s.summary  = "A ruby find and replace tool for batch editing text files."
  s.email    = "Markus@ITstrauss.eu"
  s.homepage = "https://github.com/mstrauss/findr"
  s.authors  = ['Markus Strauss']
  
  s.description = <<-EOF
A ruby find and replace tool for batch editing text files.
EOF
  
  dependencies = [
    [:test, 'rake']
    # Examples:
    # [:runtime,     "rack",  "~> 1.1"],
    # [:development, "rspec", "~> 2.1"],
  ]
  
  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  
  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.8.11"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
