require "net/http"
require "uri"
require 'openssl'
require 'rdf'
require 'sparql/client'
require 'rdf/ntriples'
require 'rdf/repository'
require 'securerandom'
require 'rdf/raptor'
require 'json/ld'

require 'rdf/turtle'
require './ldpcontainer.rb'
require './ldpresource.rb'


# == LDPClient
#
# A simple client for interacting with Linked Data Platform servers.
# 
#
# == Summary
# 
# The Linked Data Platform (LDP) is a W3C-approved approach for creating
# read/write Web interfaces based on Linked Data, and uses exclusively
# HTTP calls (GET, PUT, POST, DELETE, etc).
#
# There are two primary kinds of "thing" in LDP:
#  - a Container
#  - a Resource
#
# Containers contain things (including other Containers or Resources).
# Resources are chunks of data, and may be Linked Data or non Linked Data.
#
# == DISCLAIMER
#
# THIS SHOULD NOT BE USED FOR PRODUCTION SERVICES.  I MAKE NO GUARANTEES
# THAT IT IS USEFUL FOR ANY PURPOSE.  YOU MAY EXPERIENCE DATA CORRUPTION
# OR DATA LOSS.  THIS HAS BEEN TESTED IN ONLY ONE ENVIRONMENT, USING
# ONE SERVER.  THIS LIBRARY CURRENTLY CANNOT USE CERTIFICATE AUTHENTICATION
# ONLY BASIC AUTH IS ALLOWED AT THIS TIME.
#
# YOU HAVE BEEN WARNED!
#


dc = RDF::Vocabulary.new("http://purl.org/dc/terms/")
sio = RDF::Vocabulary.new("http://semanticscience.org/resource/")
fair = RDF::Vocabulary.new("http://purl.org/fair-ontology#")
rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
swo = RDF::Vocabulary.new("http://www.ebi.ac.uk/efo/swo/")
prov = RDF::Vocabulary.new("http://www.w3.org/ns/prov#")
ldp = RDF::Vocabulary.new("http://www.w3.org/ns/ldp#")
foaf = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
owl = RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#")



class LDPClient


  # Get/Set the LDP endpoint
  # @!attribute [rw]
  # @return [String] The endpoint
  attr_accessor :endpoint

  # Get the LDP endpoint's toplevel Container object
  # @!attribute [r]
  # @return [LDPContainer] The endpoint
  attr_reader :toplevel_container

  # Get/Set the LDP endpoints username (for basic Auth)
  # @!attribute [rw]
  # @return [String] the username
  attr_accessor :username


  # Get/Set the LDP endpoints password (for basic Auth)
  # @!attribute [rw]
  # @return [String] The password
  attr_accessor :password


  # Get/Set the string identifying the UserAgent to the server
  # @!attribute [rw]
  # @return [String] The user agent string
  attr_accessor :agent


  # Create a new instance of Patient

  # @param endpoint [String] the URL of the LDP server (must be a Container!) (required)
  # @param agent [String] the friendly string describing who I am to the server (required)
  # @param username [String] my username for basic auth (required)
  # @param password [String] my password for basic auth (required)
  # @return [LDPClient] an instance of LDPClient
  def initialize(params = {}) # get a name from the "new" call, or set a default
    @agent = "LDP_Client Ruby by Mark Wilkinson"

    @endpoint = params.fetch(:endpoint)
    @username = params.fetch(:username)
    @password = params.fetch(:password)
    uri = URI(@endpoint)
    
    @toplevel_container = LDPContainer.new({:uri => uri, :client => self})
    

    
  end



  # A utility function that SHOULD NOT BE CALLED EXTERNALLY
  #
  # @param s - subject node
  # @param p - predicate node
  # @param o - object node
  # @param repo - an RDF::Graph object
  def triplify(s, p, o, repo)

    if s.class == String
            s.strip
    end
    if o.class == String
            o.strip
    end
    if p.class == String
            p.strip
    end
    
    if s.to_s =~ /^\w+:(\/?\/?)[^\s]+/
            s = RDF::URI.new(s)
    else
      $stderr.puts "Subject #{s.to_s} must be a URI-compatible thingy"
      exit
    end
    
    if p.class == String and p =~ /^\w+:(\/?\/?)[^\s]+/
            p = RDF::URI.new(s)
    end

    if o =~ /^\w+:(\/?\/?)[^\s]+/
            o = RDF::URI.new(o)
    elsif o =~ /^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d/
            o = RDF::Literal.new(o, :datatype => RDF::XSD.date)
    else
            o = RDF::Literal.new(o, :language => :en)
    end
    #puts "inserting #{s.to_s} #{p.to_s} #{o.to_s}"
    triple = RDF::Statement(s, p, o) 
    repo.insert(triple)

    return true
  end
  

  # A utility function that SHOULD NOT BE CALLED EXTERNALLY
  #
  # @param s - subject node
  # @param p - predicate node
  # @param o - object node
  # @param repo - an RDF::Graph object
  def LDPClient.triplify(s, p, o, repo)
    return triplify(s,p,o,repo)
  end

end