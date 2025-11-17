$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'corika_invoices/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'corika_invoices'
  s.version     = CorikaInvoices::VERSION
  s.authors     = ['Karsten Richter']
  s.email       = ['kr@corika.com']
  s.homepage    = 'https://github.com/dc7kr/invoices-gem'
  s.summary     = 'An invoice generation and archive tool using mongo DB for persistence'
  s.description = 'An invoice generation and archive tool using mongo DB for persistence'
  s.license     = 'GPL'
  s.required_ruby_version = '>=3.0.0'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'countries'
  s.add_dependency 'kaminari'
  s.add_dependency 'mongoid'
  s.add_dependency 'rails', '>=  5.0'

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rails-omakase'
  s.add_development_dependency 'sqlite3'
end
