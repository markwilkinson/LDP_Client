require "ldp/version"
require "ldp/ldpresource"
require "ldp/ldpcontainer"
require "ldp/http_utils"
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


module LDP
	autoload :LDPClient, './ldp/ldpclient'
	autoload :LDPResource, './ldp/ldpresource'
	autoload :LDPContainer, './ldp/ldpcontainer'
	autoload :HTTPUtils, './ldp/http_utils'

end

