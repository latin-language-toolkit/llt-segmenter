# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'llt/segmenter/version'

Gem::Specification.new do |spec|
  spec.name          = "llt-segmenter"
  spec.version       = LLT::Segmenter::VERSION
  spec.authors       = ["Gernot Höflechner, Robert Lichstensteiner, Christof Sirk"]
  spec.email         = ["latin.language.toolkit@gmail.com"]
  spec.description   = %q{Segments text into sentences}
  spec.summary       = %q{Segments text into sentences}
  spec.homepage      = "http://latin-language-toolkit.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_dependency "llt-core"
  spec.add_dependency "llt-constants"
  spec.add_dependency "llt-logger"
end
