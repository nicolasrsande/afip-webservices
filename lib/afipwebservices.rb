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

  extend self

  attr_accessor :pkey, :cert, :env, :default_cuit

end
