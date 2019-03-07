module LDP
  
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
  
    attr_accessor :debug
    # Create a new instance of LDP::LDPClient
  
    # @param endpoint [String] the URL of the LDP server (must be a Container!) (required)
    # @param agent [String] the friendly string describing who I am to the server (optional)
    # @param username [String] my username for basic auth (required)
    # @param password [String] my password for basic auth (required)
    # @return [LDPClient] an instance of LDPClient
    #
    # The only useful thing to do after creating the LDPClient is
    # to call #toplevel_container on that object to retrieve the
    # LDPContainer object that represents the "root" of the LDP
    # Container structure.  All other Client functionalities are intended
    # to be used only by the other objects, so... don't use them :-)
    
    def initialize(params = {}) # get a name from the "new" call, or set a default
      @agent = params.fetch(:agent, "LDP::LDPClient in Ruby by Mark Wilkinson")
  
      @endpoint = params.fetch(:endpoint)
      @username = params.fetch(:username)
      @password = params.fetch(:password)
      @debug = params.fetch(:debug, false)

      uri = URI(@endpoint)
      
      @toplevel_container = LDP::LDPContainer.new({:uri => uri, :client => self})
      
  
      
    end
  
  
  
    # A utility function that SHOULD NOT BE CALLED EXTERNALLY
    #
    # @param s - subject node
    # @param p - predicate node
    # @param o - object node
    # @param repo - an RDF::Graph object
    def triplify(s, p, o, repo)
  
      if s.class == String
              s = s.strip
      end
      if p.class == String
              p = p.strip
      end
      if o.class == String
              o = o.strip
      end
      
      unless s.respond_to?('uri')
        
        if s.to_s =~ /^\w+:\/?\/?[^\s]+/
                s = RDF::URI.new(s.to_s)
        else
          $stderr.puts "Subject #{s.to_s} must be a URI-compatible thingy"
          abort "Subject #{s.to_s} must be a URI-compatible thingy"
        end
      end
      
      unless p.respond_to?('uri')
    
        if p.to_s =~ /^\w+:\/?\/?[^\s]+/
                p = RDF::URI.new(p.to_s)
        else
          $stderr.puts "Predicate #{p.to_s} must be a URI-compatible thingy"
          abort "Predicate #{p.to_s} must be a URI-compatible thingy"
        end
      end
  
      unless o.respond_to?('uri')
        if o.to_s =~ /^\w+:\/?\/?[^\s]+/
                o = RDF::URI.new(o.to_s)
        elsif o.to_s =~ /^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d/
                o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.date)
        elsif o.to_s =~ /^\d\.\d/
                o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.float)
        elsif o.to_s =~ /^[0-9]+$/
                o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.int)
        else
                o = RDF::Literal.new(o.to_s, :language => :en)
        end
      end 
      self.debug && $stderr.puts("inserting #{s.to_s} #{p.to_s} #{o.to_s}")
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
end
