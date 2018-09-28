require "net/http"
require "uri"
require 'openssl'

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
  
  def initialize (params = {}) # get a name from the "new" call, or set a default
    @endpoint = params.fetch(:endpoint)
    user = params.fetch(:username)
    pass = params.fetch(:password)
    
    uri = URI(@endpoint)
    
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    
      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth user, pass
    
      response = http.request request # Net::HTTPResponse object
    
      puts response
      puts response.body
    end
    
  end

  def get (somedisease)
    #curl -iX GET -H "Accept: text/turtle"
    #-u dba:fairevaluator
    #"http://evaluations.fairdata.solutions:8890/DAV/home/LDP/evals/"
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