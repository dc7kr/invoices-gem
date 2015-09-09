# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'corika_invoices/version'

Gem::Specification.new do |spec|
  spec.name          = "corika_invoices"
  spec.version       = CorikaInvoices::VERSION
  spec.authors       = ["Karsten Richter"]
  spec.email         = ["karsten.richter@sync.tec.com"]
  spec.description   = "MongoDB Invoicing GEM"
  spec.summary       = "Gem to create and store invoices in a MongoDB"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency("railties",">=3.2.6", "<5")
end
