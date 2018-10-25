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




# == LDP::LDPResource
#
# Object representing an LDP Resource
# 
#
# == Summary
# 
# Resources are chunks of data, in this case, in RDF.  (no other options right now, sorry!).
#
module LDP
class LDPResource
  
  # Get the Resource uri
  # @!attribute [r]
  # @return [String] The uri
  attr_accessor :uri
  
  # Get the Resource's Container object
  # @!attribute [r]
  # @return [LDP::LDPContainer] The Container
  attr_accessor :container
  
  # Get the Resource's Client object
  # @!attribute [r]
  # @return [LDP::LDPClient] The Client
  attr_accessor :client
  
  # Get the Resource's top-level Container
  # @!attribute [r]
  # @return [LDP::LDPContainer] The top-level container
  attr_accessor :toplevel_container
  #attr_accessor :body   # not sure we should use these
  #attr_accessor :graph  # not sure we should use these
  

  # Create a new instance of LDP::LDPResource

  # @param uri [String] the URL of the LDP Container (required)
  # @param client [LDP::LDPClient] the client for this Container (required)
  # @param parent [LDP::LDPContainer] the parent Container of this container (required)
  # @param top [LDP::LDPContainer] the toplevel container of this Client (required)
  # @return [LDP::LDPRersource] an instance of LDP::LDPResource
  #
  # You should never create this yourself.  Let the Client create it for you
  # You have been warned!
  #
  # The only useful functions you can call are:
  # #toplevel_container - to get the 'root' container for the current Resource
  # #parent - to get the parent container of this container
  # #get - returns the HTTP Response object representing this Resource, with a Body in text/turtle
  # #add_metadata - pass triples to annotate this RDF Resource object
  # #delete - delete this Resource (returns parent container)
  def initialize(params = {})
    @debug = false
    @container = params.fetch(:container, nil)
    return false unless @container.is_a?(LDPContainer)

    @client = params.fetch(:client, @container.client)
    @toplevel_container = params.fetch(:toplevel_container, @container.toplevel_container)

    @uri = params.fetch(:uri, false)
    unless @uri  # if I don't already exist, create me
      now = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      slug = params.fetch(:slug, now)

      myuri = _create_empty_resource_get_uri(slug)  # this fills @body and @graph, returns the "location" header
      @uri = URI.parse(myuri) if myuri
    end
    
    return false unless self.uri
    
    return self
  end

  
  # Delete this Resource

  # @return [LDP::LDPContainer]
  # little error checking is done yet!  Failures will crash.
  # The LDP::Container returned is the Parent container of this Rersource
  def delete
    parent_container = self.container

    Net::HTTP.start(self.uri.host, self.uri.port,
              :use_ssl => self.uri.scheme == 'https', 
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Delete.new(self.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['User-Agent'] = self.client.agent
      res = https.request(req)
      @debug and $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
    end
    parent_container.init_folder  # refresh the content now that this is gone
    return parent_container  # return the parent container
  end
    
  # Retrieve the Net::HTTP::Response from HTTP GET of this Resource

  # @return [Net::HTTP::Response]
  #
  # The body of the Response object is in text/turtle format
  def get()
    Net::HTTP.start(self.uri.host, self.uri.port,
              :use_ssl => self.uri.scheme == 'https', 
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Get.new(self.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['User-Agent'] = self.client.agent
      res = https.request(req)
      @debug and $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
      # TODO  THiS IS BAD!  It should first convert the message body into
      # a specific format ...right now, that format is undefined, but the body is always written
      # as turtle, so it will always be returned as turtle, I guess.  for the moment
      return res
    end
  end
  
  
  # Add a triples to the this RDF Resource

  # @param [[subject, predicate, object],...] the triples to add
  # @return self (?)
  # little error checking is done yet!  Failures will crash.
  # You can pass URLs or RDF::URI objects as subject and predicate.
  # a "best guess" will be made about what us passed as object
  # note that RDF::URI objects passed-in will be RECREATED (from to_s)
  def add_metadata(triples)
    graph = RDF::Graph.new

    triples.each do |triple|
      s,p,o = triple
      self.client.triplify(s,p,o,graph)
    end
    self._update(graph)
  end
  

  
  #def put(graph)  # TODO Validate this graph?
  #  $stderr.puts "\n\nthis cannot be PUT because it has no uri\n\n\n #{self.inspect}\n\n" and return false unless (self.uri)
  #  
  #  writer = RDF::Writer.for(:turtle)
  #  body = writer.dump(graph)
  #  
  #  Net::HTTP.start(self.uri.host, self.uri.port,
  #            :use_ssl => self.uri.scheme == 'https', 
  #            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  #
  #    req = Net::HTTP::Put.new(self.uri.path)
  #    req.basic_auth self.client.username, self.client.password
  #    req['Content-Type'] = 'text/turtle'
  #    req['Accept'] = 'text/turtle'
  #    req['User-Agent'] = self.client.agent
  #    
  #    req.body = body
  #    res = https.request(req)
  #    $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
  #  end
  #end

# used to be POST
  def _update(graph)  # TODO Validate this graph?
    @debug and $stderr.puts "\n\nthis cannot be POSTED because it has no uri\n\n\n #{self.inspect}\n\n" and return false unless (self.uri)
    response = self.get
    existinggraphobject = RDF::Graph.new
    existinggraphobject.from_ttl(response.body)
    existinggraphobject.each {|stmt| graph << stmt  }  # append

    writer = RDF::Writer.for(:turtle)
    body = writer.dump(graph)
    
    Net::HTTP.start(self.uri.host, self.uri.port,
              :use_ssl => self.uri.scheme == 'https', 
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Post.new(self.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['User-Agent'] = self.client.agent
      
      req.body = body
      res = https.request(req)
      @debug and $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
    end
  end


  def _create_empty_resource_get_uri(slug)

    Net::HTTP.start(self.container.uri.host, self.container.uri.port,
          :use_ssl => self.container.uri.scheme == 'https', 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Post.new(self.container.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['Slug'] = slug
      req['User-Agent'] = self.client.agent
      req['Link'] = '<http://www.w3.org/ns/ldp#Resource>; rel="type"'
      
      req.body = """<> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/ldp#Resource> ."""
      
  
      response = https.request(req)
      @debug and $stderr.puts "NOTE FROM CREATE OPERATION:  Response  #{response.code} #{response.message}: #{response.body}"
      newuri = response['location']
      
      #@graph = RDF::Graph.new
      #
      #RDF::Reader.for(:ntriples).new(req.body) do |reader|
      #  reader.each_statement do |statement|
      #    @graph << statement
      #  end
      #end
  
      return newuri
    end
  end

  
end
end
