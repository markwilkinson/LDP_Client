require "net/http"
require "uri"




class LDPContainer
  
  attr_accessor :uri
  attr_accessor :containers
  attr_accessor :resources
  attr_accessor :metadata
  
  def initialize(params = {}) # get a name from the "new" call, or set a default
    @containers = []
    @resources = []
    @metadata = RDF::Repository.new   # a repository can be used as a SPARQL endpoint for SPARQL::Client

    @myuri = params.fetch(:uri)
    
  end

  def add_container(uri)
    cont = LDPContainer.new({:uri => uri})
    @containers << cont
  end
  
  def add_resource(uri)
    cont = LDPResource.new({:uri => uri})
    @resources << cont
  end
  
  # pass a list of lists [ [s,p,o], [s,p.o],...]
  def add_metadata(triples) 
    triples.each do |triple|
      s,p,o = triple
      triplify(s,p,o,@metadata)
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
end