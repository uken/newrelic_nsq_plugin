# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newrelic_nsq_plugin/version'

Gem::Specification.new do |spec|
  spec.name          = "newrelic_nsq_plugin"
  spec.version       = NewrelicNsqPlugin::VERSION
  spec.authors       = ["lxfontes"]
  spec.email         = ["lxfontes@gmail.com"]

  spec.summary       = %q{NewRelic NSQ Plugin}
  spec.description   = %q{Exposes NSQ topic and channel statistics to NewRelic}
  spec.homepage      = "https://github.com/uken/newrelic_nsq_plugin"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency "newrelic_plugin", '~> 1.3'
  spec.add_runtime_dependency "faraday", '~> 0.9'
end
