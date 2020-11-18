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


# AfipWebservice is a multi-purpose wrapper for the AFIP APIs and Services
# Author: Nicolas Rodriguez (nicolasrsande@gmail.com)
#
module AfipWebservices

  # This class handles the logging options
  #
  class Logger < Struct.new(:log, :pretty_xml, :level)
    # @param opts [Hash] receives a hash with keys `log`, `pretty_xml` (both
    # boolean) or the desired log level as `level`

    def initialize(opts = {})
      self.log = opts[:log] || true
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

  class << self
    # Receiver of the logging configuration options.
    # @param opts [Hash] pass a hash with `log`, `pretty_xml` and `level` keys
    # to set them.
    def logger=(opts)
      @logger ||= Logger.new(opts)
    end

    # Sets the logger options to the default values or returns the previously
    # set logger options
    # @return [Logger]
    def logger
      @logger ||= Logger.new
    end

    # Returns the formatted logger options to be used by Savon.
    def logger_options
      logger.logger_options
    end
  end

end
