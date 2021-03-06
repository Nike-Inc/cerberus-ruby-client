# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cerberus_utils/version'

Gem::Specification.new do |spec|
  spec.name          = "cerberus_client"
  spec.version       = CerberusUtils::VERSION
  spec.authors       = ["Shaun Ford", "Joe Teibel"]
  spec.email         = ["shaun.ford@nike.com"]

  spec.summary       = ["A Ruby Client for Cerberus, a secure property store for cloud applications"]
  spec.description   = "This is a Ruby based client library for communicating with Cerberus via HTTP and enables authentication schemes specific to AWS and Cerberus. This client currently supports read-only operations (write operations are not yet implemented, feel free to open a pull request to implement write operations). To learn more about Cerberus, please visit the Cerberus website."
  spec.homepage      = "https://github.com/Nike-Inc/cerberus-ruby-client"
  spec.license       = "Apache License Version 2"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'aws-sdk-iam', '~> 1.3'
  spec.add_development_dependency 'aws-sdk-kms', '~> 1.2'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_runtime_dependency 'aws-sdk-iam', '~> 1.3'
  spec.add_runtime_dependency 'aws-sdk-kms', '~> 1.2'
end