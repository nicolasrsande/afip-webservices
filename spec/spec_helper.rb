$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bundler/setup'
require 'rspec'
require 'afipwebservices'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

AfipWebservices.cert = 'spec/fixtures/certs/cert.crt'
AfipWebservices.pkey = 'spec/fixtures/certs/pkey'
AfipWebservices.env = :test
AfipWebservices.default_cuit = '20379317376'

def fixture(file)
  File.read(file)
end
