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
    
    attr_accessor :debug  
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
      @container = params.fetch(:container, nil)
      return false unless @container.is_a?(LDPContainer)
  
      @client = params.fetch(:client, @container.client)
      @debug = self.client.debug

      @toplevel_container = params.fetch(:toplevel_container, @container.toplevel_container)
  
      @uri = params.fetch(:uri, false)

      unless @uri  # if I don't already exist, create me
        now = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
        now = now.gsub(':', '--')

        slug = params.fetch(:slug, now)
  
        myuri = _create_empty_resource_get_uri(slug)  # this fills @body and @graph, returns the "location" header
        @uri = URI.parse(myuri) if myuri
        self.uri = @uri
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
      response = LDP::HTTPUtils::delete(self.uri, {accept: "*/*"}, self.client.username, self.client.password)
      @debug and $stderr.puts "Response #{response.code}: #{response.body}"
      if response
        parent_container.init_folder  # refresh the content now that this is gone
        return parent_container  # return the parent container
      else
        stderr.puts "Delete of #{self.uri} failed for unknown reasons.  Continuing, but beware!"
        return false
      end
    end
      

    def get()      
      response = LDP::HTTPUtils::get(self.uri, {accept: "text/turtle"}, self.client.username, self.client.password)             
      return response
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
    

    def _update(graph)  # TODO Validate this graph?
      response = self.get
      unless response
        $stderr.puts "something went very wrong.  I could not retrieve #{self.uri} via HTTP GET\n\n\n#{self.inspect}"
        return false
      end
      
      existinggraphobject = RDF::Graph.new
      patchedttl = LDP::HTTPUtils::patchttl(response.body)
      existinggraphobject.from_ttl(patchedttl)
      existinggraphobject.each {|stmt| graph << stmt  }  # append
      
      writer = RDF::Writer.for(:turtle)
      body = writer.dump(graph)
      
      response = LDP::HTTPUtils::put(@uri, {accept: 'text/turtle', content_type: 'text/turtle'}, body, self.client.username, self.client.password)
      @debug and $stderr.puts "Response #{response.code} : #{response.body}"
      if response
        return self
      else
        stderr.puts "Update of #{self.uri} failed for unknown reasons.  Continuing, but beware!"
        return false
      end
    
    end
  
  
    def _create_empty_resource_get_uri(slug)
  
      parent_container = self.container
      resources = parent_container.get_resources
      resources.each do |r|
        return r if r.uri.to_s.match(/\/#{@slug}\/?$/) # check if it already exists, return it if it does
      end

      headers = {accept: 'text/turtle', content_type: 'text/turtle', "Slug" => slug, "Link" => '<http://www.w3.org/ns/ldp#Resource>; rel="type"'}
        
      payload = """<> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/ns/ldp#Resource> ."""
      @debug and $stderr.puts   parent_container.uri, headers, payload, self.client.username, self.client.password
      response = LDP::HTTPUtils::post(parent_container.uri, headers, payload, self.client.username, self.client.password)
      if response
        newuri = response.headers[:location]  
        unless newuri
          abort "PROBLEM - cannot get location of new resource.  This resource may or may not have been created! BAILING just to be safe"
        end
        return newuri
      else
        abort "PROBLEM - cannot get response when creating resource in #{self.container.uri}.  BAILING just to be safe"
      end    
    end
  
    
  end
end
