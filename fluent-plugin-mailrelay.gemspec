# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-mailrelay"
  spec.version       = "0.0.0"
  spec.authors       = ["Yudai Kato"]
  spec.email         = ["grandeur09@gmail.com"]

  spec.summary       = %q{Output plugin to trace mail relayed in intranetwork.}
  spec.description   = %q{trace mail relayed in intra network.}
  spec.homepage      = "https://github.com/yudai09/fluent-plugin-mailrelay.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "fluentd"
  spec.add_runtime_dependency("lru_redux", [">= 0.8.4"])
end
