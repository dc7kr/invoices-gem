$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "corika_invoices/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "corika_invoices"
  s.version     = CorikaInvoices::VERSION
  s.authors     = ["Karsten Richter"]
  s.email       = ["kr@corika.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of CorikaInvoices."
  s.description = "TODO: Description of CorikaInvoices."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.5.1"
  s.add_dependency "mongoid", "~> 5.0.0"

  s.add_development_dependency "sqlite3"
end
