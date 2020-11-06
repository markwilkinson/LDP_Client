# == LDP::LDPContainer
#
# Object representing an LDP Container
# 
#
# == Summary
# 
# Containers contain things (including other Containers or Resources).
# Resources are chunks of data, and may be Linked Data or non Linked Data.
#
module LDP
  
  class LDPContainer
    
    # Get the Container uri
    # @!attribute [r]
    # @return [URI] The uri object
    attr_accessor :uri
    
    # Get the current client
    # @!attribute [r]
    # @return [LDP::LDPClient] this container's client object
    attr_accessor :client
    
    # Get the parent container
    # @!attribute [r]
    # @return [LDP::LDPContainer] This container's parent container
    attr_accessor :parent
    
    # Get the toplevel container object
    # @!attribute [r]
    # @return [LDP::LDPContainer] The endpoint
    attr_accessor :toplevel_container
    
    # Get the Net::HTTP::Reponse object from GET of this container (may not be set)
    # @!attribute [r]
    # @return [Net::HTTP::Reponse] represents GET of this container
    attr_accessor :http_response
    
    # Get the RDF::Graph representing this Container (may not be set)
    # @!attribute [r]
    # @return [RDF::Graph] The model
    attr_accessor :current_model
  
    # Do Not Touch This
    # @!attribute [r]
    # @return [Boolean] should I read the entire folder or not
    attr_accessor :init
    
    
    attr_accessor :debug
    # Create a new instance of LDP::LDPContainer
  
    # @param uri [String] the URL of the LDP Container (required)
    # @param client [LDP::LDPClient] the client for this Container (required)
    # @param parent [LDP::LDPContainer] the parent Container of this container (required)
    # @param top [LDP::LDPContainer] the toplevel container of this Client (required)
    # @return [LDPContainer] an instance of LDPClient
    #
    # You should never create this yourself.  Let the Client create it for you
    # You have been warned!
    #
    # The only useful functions you can call are:
    # #get_containers - to get all the containers in this container
    # #get_resources - to get all of the non-container resources in this container
    # #toplevel_container - to get the 'root' container for the current Client
    # #parent - to get the parent container of this container
    # #get - returns the HTTP Response object representing this Container, with a Body in text/turtle
    # #add_container - create a new container inside of this container
    # #add_resource - create a new (RDF-only!) resource inside of this container
    # #add_metadata - pass triples to annotate this container object
    # #delete - delete this container (and everyting in it!)
      
    def initialize(params = {}) # get a name from the "new" call, or set a default
      @current_model = false
      @containers = []
      @resources = []
  
      @uri = params.fetch(:uri, false)  # this should be failure
      abort "cannot create a Container with no identifier... I'm dying!" unless @uri
      case @uri
      when String
        @uri = URI.parse(@uri)
      end
  
      @client = params.fetch(:client, self.client)
      @parent = params.fetch(:parent, self.parent)
      @toplevel_container = params.fetch(:top, self)  # if there is no toplevel, then I must be!
      @init = params.fetch(:init, true)
      @debug = self.client.debug
      #now = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      #@slug = params.fetch(:slug, now)
      
      if @init  # should I initialize by reading the content
        init_folder
      end
      
      return self
    
    end
  
  
    # Refreshes the content of the Container object with the current state on the server
  
    # You should never execute this command
    # You have been warned!
    def init_folder
      @containers = []
      @resources = []
      @http_response = self.get
      if @http_response
        _parse_ldp(@http_response.body)
      elsif !@http_response
        return false
      end
      @init = true
    end
    
    
    # Retrieve the contained LDP::LDPContainers
  
    # @return [Array[LDPContainer]]
    #
    # to explore the content of the container  
    def get_containers
      init_folder unless @init  # have I been initialized?
      return @containers  
    end
  
    # Retrieve the contained LDP::LDPResource
  
    # @return [Array[LDPResource]]
    #
    # to explore the content of the container  
    def get_resources
      init_folder unless @init  # have I been initialized?
      return @resources      
    end
    
  
    # Retrieve the Net::HTTP::Response from HTTP GET of this container
  
    # @return [Net::HTTP::Response]
    #
    # The body of the Response object is in text/turtle format
    def get   # replace this with the call that I use in my class that follows redirects
      @debug and $stderr.puts "getting container"
      @debug and $stderr.puts self.uri, {accept: "text/turtle"}, self.client.username, self.client.password
      response = LDP::HTTPUtils.get(self.uri, {accept: "text/turtle"}, self.client.username, self.client.password)
      if response
          return response
      else
          @debug and $stderr.puts "FAILED to find this container #{self.uri.to_s}"  # do something more useful, one day
          return false
      end
    end
  
    # Add a new Container inside of this Container
  
    # @param slug [String] the indication of what you want the filename to be, if possible
    # @return [LDP::LDPContainer] the LDPContainer object for the new container
    # will return the object representing an existing container if there is
    # a container with the uri that would result from that slug...
    # no error checking is done yet!  Failures will crash.
  
    def add_container(params = {})
      now = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      now = now.gsub(':', '--')

      @slug = params.fetch(:slug, now)
      
      containers = self.get_containers
      containers.each do |c|
        return c if c.uri.to_s.match(/\/#{@slug}\/?$/) # check if it already exists
      end
      
      headers = {accept: 'text/turtle', content_type: 'text/turtle', "Slug" => @slug, "Link" => '<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"'}
        
      payload = """@prefix ldp: <http://www.w3.org/ns/ldp#> . 
                      <> a ldp:Container, ldp:BasicContainer ."""
        
      response = LDP::HTTPUtils::post(self.uri, headers, payload, self.client.username, self.client.password)
      if response
        newuri = response.headers[:location]  
        newcont = self._add_container({:uri => newuri,
                                     :client => self.client,
                                     :parent => self,
                                     :top => self.toplevel_container,
                                     :init => true})
        unless newcont
          abort "PROBLEM - cannot add new container with id #{newuri}.  BAILING just to be safe"
        end
        return newcont
      else
        abort "PROBLEM - cannot create container into #{self.uri}.  BAILING just to be safe"
      end
      
    end
    
    
    # Add a new RDF Resource inside of this Container
  
    # @param slug [String] the indication of what you want the filename to be, if possible
    # @return [LDP::LDPResource] the LDPResource object for the new Resource
    # no error checking is done yet!  Failures will crash.
    # At this time, only RDF resources are allowed.  Sorry, that's all I needed!
    
    def add_rdf_resource(params = {})
      now = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      slug = params.fetch(:slug, now)
  
      client = params.fetch(:client, self.client)
      container = params.fetch(:container, self)
      top = params.fetch(:top, @toplevel_container)
      
      res = LDP::LDPResource.new(:container => container,
                            :slug => slug,
                            :toplevel => top,
                            :client => client,
                            :debug => @debug)
      
      self.init_folder  # refresh myself
      return res
  
    end
  
    # Add a triples to the definition of this Container (annotate the Container)
  
    # @param slug [[subject, predicate, object],...] the triples to add
    # @return self (?)
    # little error checking is done yet!  Failures will crash.
    # You can pass URLs or RDF::URI objects as subject and predicate.
    # a "best guess" will be made about what us passed as object
    # note that RDF::URI objects passed-in will be RECREATED (from to_s)
    def add_metadata(triples)
      self.init_folder unless self.init
      graph = RDF::Graph.new
  
      triples.each do |triple|
        s,p,o = triple
        self.client.triplify(s,p,o,graph)
      end
      self._update(graph)
    end
    

    ## Remove triples from the Container annotations (annotate the Container)
    #
    ## @param slug [[subject, predicate, object],...] the triples to remove
    ## @return self (?)
    ## little error checking is done yet!  Failures will crash.
    ## You can pass URLs or RDF::URI objects as subject and predicate.
    ## a "best guess" will be made about what us passed as object
    ## note that RDF::URI objects passed-in will be RECREATED (from to_s)
    #def delete_metadata(triples)
    #  self.init_folder unless self.init
    #  graph = RDF::Graph.new
    #
    #  triples.each do |triple|
    #    s,p,o = triple
    #    self.client.triplify(s,p,o,graph)
    #  end
    #  self._update(graph)
    #end
    #
    #
    #def _delete_update(graph)  # TODO Validate this graph?
    #  response = self.get
    #  unless response
    #    $stderr.puts "something went very wrong.  I could not retrieve #{self.uri} via HTTP GET\n\n\n#{self.inspect}"
    #    return false
    #  end
    #  
    #  existinggraphobject = RDF::Graph.new
    #  existinggraphobject.from_ttl(response.body)
    #  existinggraphobject.each {|stmt| graph << stmt  }  # append
    #  
    #  writer = RDF::Writer.for(:turtle)
    #  body = writer.dump(graph)
    #  
    #  response = LDP::HTTPUtils::put(self.uri, {accept: 'text/turtle', content_type: 'text/turtle'}, body, self.client.username, self.client.password)
    #  @debug and $stderr.puts "Response #{response.code}: #{response.body}"
    #  if response
    #    self.init_folder
    #    return self
    #  else
    #    stderr.puts "Update of #{self.uri} failed for unknown reasons.  Continuing, but beware!"
    #    return false
    #  end
    #
    #end

    
    
    
    
    # Delete this Container and all of its content
  
    # @return [LDP::LDPContainer]
    # little error checking is done yet!  Failures will crash.
    # The LDP::Container returned is the Parent container of this Container
  
    def delete()
      parent_container = self.parent
      @debug and $stderr.puts "Cannot delete the toplevel container" and return false if self.uri == self.toplevel_container.uri
      
      response = LDP::HTTPUtils::delete(self.uri, {accept: "text/turtle"}, self.client.username, self.client.password)
      @debug and $stderr.puts "Response #{response.code}: #{response.body}"
      if response
        parent_container.init_folder  # refresh the content now that this is gone
        return parent_container  # return the parent container
      else
        stderr.puts "Delete of #{self.uri} failed for unknown reasons.  Continuing, but beware!"
        return false
      end
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
      
      response = LDP::HTTPUtils::put(self.uri, {accept: 'text/turtle', content_type: 'text/turtle'}, body, self.client.username, self.client.password)
      @debug and $stderr.puts "Response #{response.code}: #{response.body}"
      if response
        self.init_folder
        return self
      else
        $stderr.puts "Update of #{self.uri} failed for unknown reasons.  Continuing, but beware!"
        return false
      end
    
    end
    
      
    def _parse_ldp(response)
      repo = RDF::Repository.new   # a repository can be used as a SPARQL endpoint for SPARQL::Client
      graph = RDF::Graph.new
      patchedttl = LDP::HTTPUtils::patchttl(response)
      graph.from_ttl(patchedttl)
      #puts graph.count
      repo.insert(*graph)
      @current_model = repo  # set the current RDF model for this container
      
      query = <<END
      PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
      PREFIX ldp:	<http://www.w3.org/ns/ldp#> 
      SELECT ?cont
      WHERE {
             <#{@uri.to_s}> ldp:contains ?cont .
             ?cont a ldp:BasicContainer
      }
END
      
      sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
      result = sparql.query(query)  # Execute query
      
      result.each do |solution|
        self._add_container({:uri => solution[:cont], :init => false})      
      end
  
      query = <<END2
      PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
      PREFIX ldp:	<http://www.w3.org/ns/ldp#> 
      SELECT ?res
      WHERE {
             <#{@uri.to_s}> ldp:contains ?res .
             ?res a ldp:Resource .
             MINUS { ?res a ldp:BasicContainer . }
      }
END2
  
      sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
      result = sparql.query(query)  # Execute query
      
      result.each do |solution|
        self._add_resource({:uri => solution[:res]})      
      end
    end
  
  
  
    def _add_resource(params = {})
      uri = params.fetch(:uri, false)
      return false unless uri
      client = params.fetch(:client, self.client)
      container = params.fetch(:container, self)
      top = params.fetch(:top, @toplevel_container)
      
      res = LDP::LDPResource.new({   :uri => uri,
                                :client => client,
                                :container => container,
                                :top => top,
                              })
      @resources << res
      return res
    end
  
  
    def _add_container(params = {})
      uri = params.fetch(:uri, false)
      return false unless uri
      client = params.fetch(:client, self.client)
      parent = params.fetch(:parent, self)
      top = params.fetch(:top, @toplevel_container)
      init = params.fetch(:init, false)
      
      cont = LDP::LDPContainer.new({ :uri => uri,
                                :client => client,
                                :parent => parent,
                                :top => top,
                                :init => init,
                                :format => :turtle
                              })
      @containers << cont
      return cont
    end
    
  end


end
