require "ldp_simple/version"
require "ldp_simple/ldpclient"
require "ldp_simple/ldpresource"
require "ldp_simple/ldpcontainer"
require "ldp_simple/http_utils"
require "net/http"
require "uri"
require 'openssl'
require 'rdf'
require 'sparql/client'
require 'rdf/ntriples'
require 'rdf/repository'
require 'rdf/turtle'
require 'rdf/raptor'
require 'securerandom'
require 'json/ld'
require 'rest-client'
require 'digest'

module LDP
	#autoload :LDPClient, 'ldp_simple/ldpclient'
	#autoload :LDPResource, 'ldp_simple/ldpresource'
	#autoload :LDPContainer, 'ldp_simple/ldpcontainer'
	#autoload :HTTPUtils, 'ldp_simple/http_utils'

   def LDP.hello
	   puts "hello"
   end
end

