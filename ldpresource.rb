require "net/http"
require "uri"

#uri = URI.parse("http://google.com/")

# Shortcut
#response = Net::HTTP.get_response(uri)

# Will print response.body
#Net::HTTP.get_print(uri)

# Full
#http = Net::HTTP.new(uri.host, uri.port)
#response = http.request(Net::HTTP::Get.new(uri.request_uri))

class LDPResource

  attr_accessor :endpoint
  
  def initialize (params = {}) # get a name from the "new" call, or set a default
    @endpoint = params.fetch(:endpoint)
    
  end

  def get (somedisease)
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
  
  def head (somedisease)

  end

  def put (somedisease)

  end

  def post (somedisease)
    #curl -iX POST -H "Content-Type: text/turtle"
    #-u dav:fairevaluations
    #--data-binary @t.ttl
    #-H "Slug: test8"
    #-H 'Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type"'
    #"http://evaluations.fairdata.solutions/DAV/home/LDP/evals"

  end
  
end