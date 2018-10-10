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


class LDPResource
  attr_accessor :uri
  attr_accessor :parent
  attr_accessor :client
  attr_accessor :toplevel_container
  attr_accessor :body
  attr_accessor :graph
  
  def initialize(params = {}) # get a name from the "new" call, or set a default
    @graph = RDF::Graph.new
    @parent = nil
    @client = nil
    @toplevel_container = nil
    @uri = params.fetch(:uri, nil)
    case uri
    when String
      @uri = URI.parse(@uri)
    end

    mygraph = params.fetch(:graph, """@prefix ldp: <http://www.w3.org/ns/ldp#> . 
                                      <> a ldp:Resource .""")
    format = params.fetch(:format, :turtle)  # must be something returned from Format.for(xxx)
    
    $stderr.puts "must provide a graph" and return false unless mygraph
    

    case mygraph
      when String && format.eql?(:turtle)
        require 'rdf/raptor'
        RDF::Reader.for(format).new(mygraph) do |reader|
          reader.each_statement do |statement|
            @graph << statement
          end
        end
      when String
        RDF::Reader.for(format).new(mygraph) do |reader|
          reader.each_statement do |statement|
            @graph << statement
          end
        end
      when mygraph.class =~ /Graph/
        @graph = mygraph
    end

    writer = RDF::Writer.for(:turtle)
    @body = writer.dump(graph)

  end

  def delete
    parent_container = self.parent

    Net::HTTP.start(self.uri.host, self.uri.port,
              :use_ssl => self.uri.scheme == 'https', 
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Delete.new(self.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['User-Agent'] = self.client.agent
      res = https.request(req)
      $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
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
      $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
      # TODO  THiS IS BAD!  It should first convert the message body into
      # a specific format ...right now, that format is undefined, but the body is always written
      # as turtle, so it will always be returned as turtle, I guess.  for the moment
      return res.body
    end
  end
  
  def head()
  end

  def put()  # TODO Validate this graph?
    $stderr.puts "\n\nthis cannot be PUT because it has no uri\n\n\n #{self.inspect}\n\n" and return false unless self.uri && self.graph
    
    writer = RDF::Writer.for(:turtle)
    body = writer.dump(self.graph)
    
    Net::HTTP.start(self.uri.host, self.uri.port,
              :use_ssl => self.uri.scheme == 'https', 
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
  
      req = Net::HTTP::Put.new(self.uri.path)
      req.basic_auth self.client.username, self.client.password
      req['Content-Type'] = 'text/turtle'
      req['Accept'] = 'text/turtle'
      req['User-Agent'] = self.client.agent
      
      req.body = body
      res = https.request(req)
      $stderr.puts "Response #{res.code} #{res.message}: #{res.body}"
    end
  end

  def post()
  end
  
end