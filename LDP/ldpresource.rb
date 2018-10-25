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


module LDP
class LDPResource
  attr_accessor :uri
  attr_accessor :container
  attr_accessor :client
  attr_accessor :toplevel_container
  #attr_accessor :body   # not sure we should use these
  #attr_accessor :graph  # not sure we should use these
  
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
  
  
  
  def add_metadata(triples)
    graph = RDF::Graph.new

    triples.each do |triple|
      s,p,o = triple
      self.client.triplify(s,p,o,graph)
    end
    self.update(graph)
  end
  

  
  def head()
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
  def update(graph)  # TODO Validate this graph?
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
