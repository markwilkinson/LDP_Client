require "net/http"
require "uri"




class LDPContainer
  
  attr_accessor :myuri
  attr_accessor :containers
  attr_accessor :resources
  attr_accessor :metadata
  attr_accessor :client
  attr_accessor :init  # have I been initialized with content from teh server?
  attr_accessor :http_response
  
  def initialize(params = {}) # get a name from the "new" call, or set a default
    @needs_init = 0
    @containers = []
    @resources = []
    @metadata = RDF::Repository.new   # a repository can be used as a SPARQL endpoint for SPARQL::Client

    @myuri = params.fetch(:uri)
    @client = params.fetch(:client)
    @needs_init = params.fetch(:init, false) if 

    @http_response = check_exists
    if @http_response and !@init
      parse_ldp(response.body)
      self.init = 1
    elsif !@http_response
      return false
    end
    
    #puts response.header
    return self
  
  end

  def add_container(params)
    uri = params[:uri]
    client = params[:client] || self.client
    cont = LDPContainer.new({:uri => uri, :client => client})
    @containers << cont
  end
  
  def add_resource(uri)
    cont = LDPResource.new({:uri => uri})
    @resources << cont
  end
  
  # pass a list of lists [ [p,o], [p.o],...]
  def add_metadata(triples) 
    triples.each do |triple|
      s,p,o = triple
      triplify(s,p,o,@metadata)
    end
  end
  
  def check_exists
    Net::HTTP.start(@myuri.host, @myuri.port,
    :use_ssl => @myuri.scheme == 'https', 
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
  
      request = Net::HTTP::Get.new @myuri.request_uri
      request["User-Agent"] = "My Ruby Script"
      request["Accept"] = "text/turtle"
  
      request.basic_auth self.client.username, self.client.password
    
      response = http.request request # Net::HTTPResponse object
    
      if ["200", "201", "202", "203", "204"].include?(response.code)
        return response
        #parse_ldp(response.body)
      else
        puts "bummer #{response}"
        return false
      end
      return response
    end
  end
  
      
      
  def commit
    
    #updatequery = ""
#    WITH GRAPH  <http://127.0.0.1:3000/dendro_graph>  
#DELETE 
#{ 
#  :teste  dc:creator      ?o0 .
#  :teste  dc:title        ?o1 .
#  :teste  dc:description  ?o2 .
#}
#INSERT 
#{ 
#  :teste  dc:creator      "Creator%201" .
#  :teste  dc:creator      "Creator%202" .
#  :teste  dc:title        "Title%201" .
#  :teste  dc:description  "Description%201" .
#} 
#WHERE 
#{ 
#  :teste  dc:creator      ?o0 .
#  :teste  dc:title        ?o1 .
#  :teste  dc:description  ?o2 .
#} 
    #code
  end
  
  def _getHeaders
    uri = @me
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    
        request = Net::HTTP::Get.new uri.request_uri
        request["User-Agent"] = "My Ruby Script"
        request["Accept"] = "text/turtle"
  
        request.basic_auth user, pass
      
        response = http.request request # Net::HTTPResponse object
      
        if ["200", "201", "202", "203", "204"].include?(response.code)
          puts response.body
          parse_ldp(response.body, uri)
        else
          puts "bummer #{response}"
        end
      end
  end
    
  def blah
    #curl -iX GET -H "Accept: text/turtle"
    #-u dba:fairevaluator
    #"http://evaluations.fairdata.solutions:8890/DAV/home/LDP/evals/"
    uri = URI.parse("@endpoint")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "My Ruby Script"
    request["Accept"] = "*/*"
    
    response = http.request(request)
    
    # Get specific header
    response["content-type"]
    # => "text/html; charset=UTF-8"
    
    # Iterate all response headers.
    response.each_header do |key, value|
      p "#{key} => #{value}"
    end
    # => "location => http://www.google.com/"
    # => "content-type => text/html; charset=UTF-8"
    # ...
    
    # Alternatively, reach into private APIs.
    p response.instance_variable_get("@header")
    # => {"location"=>["http://www.google.com/"], "content-type"=>["text/html; charset=UTF-8"], ...}
  end
  
  def head()

  end

  def put()

  end

  def post()
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
#	else
#		exit 
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
  
    
  def parse_ldp(response)
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
           <#{@myuri}> ldp:contains ?cont .
           ?cont a ldp:BasicContainer
    }
END
    
    sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
    result = sparql.query(query)  # Execute query
    
    result.each do |solution|
      # puts "LDP contains the container:  #{solution[:cont]}"
      self.add_container({:uri => solution[:cont], :init => 0})      
    end

    query = <<END2
    PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
    PREFIX ldp:	<http://www.w3.org/ns/ldp#> 
    SELECT ?cont
    WHERE {
           <#{@myuri}> ldp:contains ?cont .
           ?cont a ldp:Resource
    }
END2

    sparql = SPARQL::Client.new(repo)    # Exactly the same as above...
    result = sparql.query(query)  # Execute query
    
    result.each do |solution|
      # puts "LDP contains the container:  #{solution[:cont]}"
      self.add_resource(solution[:cont])      
    end


  end
  
end

