
# -*- encoding: utf-8 -*-
$:.push('lib')
require "findr/version"

Gem::Specification.new do |s|
  s.name     = "findr"
  s.version  = Findr::VERSION.dup
  s.licenses = ['MIT']
  s.date     = "2014-11-25"
  s.summary  = "A ruby find and replace tool for mass editing text files."
  s.email    = "Markus@ITstrauss.eu"
  s.homepage = "https://github.com/mstrauss/findr"
  s.authors  = ['Markus Strauss']

  s.description = <<-EOF
A ruby find and replace tool for mass editing of text files.
EOF

  dependencies = [
    [:test, 'rake', '~> 10.0']
    # Examples:
    # [:runtime,     "rack",  "~> 1.1"],
    # [:development, "rspec", "~> 2.1"],
  ]

  s.files         = Dir['**/*']-Dir['*.lock','*.txt','*.gem']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 1.8.7'

  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
