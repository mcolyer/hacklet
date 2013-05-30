# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hacklet/version'

Gem::Specification.new do |gem|
  gem.name          = "hacklet"
  gem.version       = Hacklet::VERSION
  gem.authors       = ["Matt Colyer"]
  gem.email         = ["matt@colyer.name"]
  gem.description   = %q{An Open Source client for the Modlet (smart) outlet}
  gem.summary       = %q{A daemon, written in ruby, for controlling the Modlet outlet.}
  gem.homepage      = "http://github.com/mcolyer/hacklet"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "serialport", "~>1.1.0"
  gem.add_dependency "bindata", "~>1.5.0"
  gem.add_dependency "slop", "~>3.4.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
