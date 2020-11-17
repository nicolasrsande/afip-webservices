# DEPENDENCIES
require 'bundler/setup'
require 'forwardable'
require 'builder'
require 'base64'
require 'httpclient'
require 'savon'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'afipwebservices/core_ext/hash'
# ERRORS
require 'afipwebservices/errors/error'
require 'afipwebservices/errors/response_error'
require 'afipwebservices/errors/server_error'
require 'afipwebservices/errors/network_error'
# MISC
require 'afipwebservices/client'
require 'afipwebservices/constants'
require 'afipwebservices/version'
require 'afipwebservices/types_conversion'
# WSAA
require 'afipwebservices/wsaa'
# WSFE
require 'afipwebservices/wsfe/wsfe_reference'
require 'afipwebservices/wsfe/wsfe'
require 'afipwebservices/wsfe/wsfe_invoice'



module AfipWebservices
  
  # This class handles the logging options
  #
  class Logger < Struct.new(:log, :pretty_xml, :level)
    # @param opts [Hash] receives a hash with keys `log`, `pretty_xml` (both
    # boolean) or the desired log level as `level`

    def initialize(opts = {})
      self.log = opts[:log] || false
      self.pretty_xml = opts[:pretty_xml] || log
      self.level = opts[:level] || :debug
    end

    # @return [Hash] returns a hash with the proper logging optios for Savon.
    def logger_options
      { log: log, pretty_print_xml: pretty_xml, log_level: level }
    end
  end

  extend self

  attr_accessor :pkey, :cert, :env, :default_cuit

end
