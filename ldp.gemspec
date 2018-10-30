
lib = File.expand_path("./lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ldp/version"

Gem::Specification.new do |spec|
  spec.name          = "ldp"
  spec.version       = '0.0.1' 
  spec.authors       = ["Mark Wilkinson"]
  spec.email         = ["markw@illuminae.com"]

  spec.summary       = %q{a primitive client for Linked Data Platform.}
  spec.description   = %q{a primitive client for Linked Data Platform which has only been tested against the Virtuoso OS version implementation of LDP}
  spec.homepage      = "https://github.com/markwilkinson/LDP_Client"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'openssl', "~> 2.1", ">=2.1.2"
  spec.add_development_dependency 'rdf', '~> 3.0', '>= 3.0.5'
  spec.add_development_dependency 'sparql-client', '~> 3.0', '>= 3.0.0'
  spec.add_development_dependency 'rdf-raptor', '~> 2.2', '>= 2.2.0'
  spec.add_development_dependency 'json-ld', '~> 3.0', '>= 3.0.2'
  spec.add_development_dependency 'rdf-turtle', '~> 3.0', '>= 3.0.3'


end
