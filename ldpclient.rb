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
require_relative './ldpcontainer.rb'
require_relative './ldpresource.rb'

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

  def initialize(params = {}) # get a name from the "new" call, or set a default
    @endpoint = params.fetch(:endpoint)
    @username = params.fetch(:username)
    @password = params.fetch(:password)
    uri = URI(@endpoint)
    
    @toplevel_container = LDPContainer.new({:uri => uri, :client => self})
    
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    
      request = Net::HTTP::Get.new uri.request_uri
      request["User-Agent"] = "My Ruby Script"
      request["Accept"] = "text/turtle"

      request.basic_auth @username, @password
    
      response = http.request request # Net::HTTPResponse object
    
      if ["200", "201", "202", "203", "204"].include?(response.code)
        puts response.body
        parse_ldp(response.body, uri)
      else
        puts "bummer #{response}"
      end
      
    end
    
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
  
  def parse_ldp(response, uri)
    repo = RDF::Repository.new   # a repository can be used as a SPARQL endpoint for SPARQL::Client
    graph = RDF::Graph.new
    graph.from_ttl(response)
    #puts graph.count
    repo.insert(*graph)
    
    query = <<END
    PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
    PREFIX ldp:	<http://www.w3.org/ns/ldp#> 
    SELECT ?cont
    WHERE {
           <#{uri}> ldp:contains ?cont .
           ?cont a ldp:BasicContainer
    }
END
    
    sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
    result = sparql.query(query)  # Execute query
    
    result.each do |solution|
      # puts "LDP contains the container:  #{solution[:cont]}"
      @toplevel_container.add_container(solution[:cont])      
    end

    query = <<END2
    PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
    PREFIX ldp:	<http://www.w3.org/ns/ldp#> 
    SELECT ?cont
    WHERE {
           <#{uri}> ldp:contains ?cont .
           ?cont a ldp:Resource
    }
END2

    sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
    result = sparql.query(query)  # Execute query
    
    result.each do |solution|
      # puts "LDP contains the container:  #{solution[:cont]}"
      @toplevel_container.add_resource(solution[:cont])      
    end


  end
  
  
end