require_relative 'lib/afipwebservices/version'

Gem::Specification.new do |spec|
  spec.name          = 'afipwebservices'
  spec.version       = Afipwebservices::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['nicolasrsande']
  spec.email         = ['nicolasrsande@gmail.com']
  spec.description   = 'Adaptador para el Web Service de Facturacion Electrónica de AFIP'
  spec.summary       = 'Adaptador WSFE'
  spec.homepage      = 'https://github.com/nicolasrsande/afipwebservices'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
  
  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'builder'
  spec.add_dependency 'httpclient'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'savon', '~> 2.11.0'

  spec.add_development_dependency(%{rake}, ['~> 10.0.0'])
  spec.add_development_dependency(%{rspec}, ['~> 2.14.0'])
  spec.add_development_dependency('mocha')
  spec.add_development_dependency('guard-rspec')
  spec.add_development_dependency('rubocop', '0.88.0')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('pry-byebug')
end
