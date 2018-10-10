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

#uri = URI.parse("http://google.com/")

# Shortcut
#response = Net::HTTP.get_response(uri)

# Will print response.body
#Net::HTTP.get_print(uri)

# Full
#http = Net::HTTP.new(uri.host, uri.port)
#response = http.request(Net::HTTP::Get.new(uri.request_uri))

#
#require 'openssl'
#
#uri = URI('https://localhost/')
#
#Net::HTTP.start(uri.host, uri.port,
#  :use_ssl => uri.scheme == 'https', 
#  :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
#
#  request = Net::HTTP::Get.new uri.request_uri
#  request.basic_auth 'matt', 'secret'
#
#  response = http.request request # Net::HTTPResponse object
#
#  puts response
#  puts response.body
#end


class LDPClient

  attr_accessor :endpoint
  attr_accessor :toplevel_container
  attr_accessor :username
  attr_accessor :password
  attr_accessor :agent

  def initialize(params = {}) # get a name from the "new" call, or set a default
    @agent = "LDP_Client Ruby by Mark Wilkinson"

    @endpoint = params.fetch(:endpoint)
    @username = params.fetch(:username)
    @password = params.fetch(:password)
    uri = URI(@endpoint)
    
    @toplevel_container = LDPContainer.new({:uri => uri, :client => self})
    

    
  end

  def get(somedisease)
    #curl -iX GET -H "Accept: text/turtle"
    #-u dba:fairevaluator
    #"http://evaluations.fairdata.solutions:8890/DAV/home/LDP/evals/"
  end
  
  def head(somedisease)

  end

  def put(somedisease)

  end

  def post(somedisease)
    #curl -iX POST -H "Content-Type: text/turtle"
    #-u dav:fairevaluations
    #--data-binary @t.ttl
    #-H "Slug: test8"
    #-H 'Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type"'
    #"http://evaluations.fairdata.solutions/DAV/home/LDP/evals"

  end


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
    
    if s =~ /^\w+:(\/?\/?)[^\s]+/
            s = RDF::URI.new(s)
    else
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
  

end