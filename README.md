# LDP

A simple Linked Data Platform (LDP) Client in Ruby

# DISCLAIMER

While you are free to try this, and see if it is suitable for your needs in a testing environment,

THIS SHOULD NOT BE USED FOR PRODUCTION SERVICES.  I MAKE NO GUARANTEES
THAT IT IS USEFUL FOR ANY PURPOSE AT ALL.  YOU MAY EXPERIENCE DATA CORRUPTION
OR DATA LOSS.  THIS HAS BEEN TESTED IN ONLY ONE ENVIRONMENT, USING
ONE SERVER.

YOU HAVE BEEN WARNED! ...YOU HAVE BEEN WARNED!!!!


# Discussion

* This library currently is limited to basic authentication (you must supply a username and password)

* The libraries use only GET, PUT, POST.

* The "add_metadata" functions of both Container and Resource objects function by pulling-in
the current RDF of that object, injecting new triples, then PUTting the object back again.

* Deleting individual triples is currently not possible.

## Example of Usage

    
    require 'ldp_simple'
    
    
    # create the vocabularies I will use
    foaf = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
    rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
    foaf = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
    
    
    
    cli = LDP::LDPClient.new({
            :endpoint => "http://example.org/LDP/toplevelContainer/",
            :username => "username",
            :password => "password"})
    
    top = cli.toplevel_container # cont is a LDPContainer object
    puts "starting container #{top.uri}"
    
    # Create new LDPContainer
    newcontainer = top.add_container(:slug => "ThisIsANewContainer") 
    # Add metadata ABOUT THE CONTAINER ITSELF
    newcontainer.add_metadata([ [newcontainer.uri, rdfs.label, "My New Container"] ])
    
    # Create an LDP Resource inside of a Container
    newresource = top.add_rdf_resource(:slug => "ThisIsAResource")
    # Add RDF triples to that new resoruce
    newresource.add_metadata([
                [newresource.uri, rdfs.label, "I like LDP Resources"],
                [newresource.uri, foaf.primaryTopic, "Linked Data Platform Ruby"]	    
                ]) 
    
    http_content = newcontainer.get
    puts "The RDF of this Container in Turtle format is: \n #{http_content.body}\n\n"
    
    http_content = newresource.get
    puts "The RDF of this Resource in Turtle format is: \n #{http_content.body}\n\n"
    
    somecontainer = top.get_containers.first  # returns first LDPContainer object
    puts "container is #{somecontainer.uri}"
    
    someresource = top.get_resources.first  # returns first LDPResource object
    puts "resource is #{someresource.uri}"
    
    # bounces you up to the parent container after deleting
    parentcontainer = newcontainer.delete
    puts "DELETED.  Parent container is #{parentcontainer.uri}"
    
    # bounces you up to the parent container after deleting
    parentcontainer = newresource.delete
    puts "DELETED.  Parent container is #{parentcontainer.uri}"


