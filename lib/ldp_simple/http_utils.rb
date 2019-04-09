module LDP
      
module HTTPUtils
	require 'rest-client'

	def self.get(url, headers = {accept: "*/*"}, user = "", pass="")  # username and password go into headers as user: xxx and password: yyy
		
		
		begin
			response = RestClient::Request.execute({
					method: :get,
					url: url.to_s,
					user: user,
					password: pass,
					headers: headers})
			return response
		rescue RestClient::ExceptionWithResponse => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue RestClient::Exception => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue Exception => e
			$stderr.puts e
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		end		  # you can capture the Exception and do something useful with it!\n",
	end


	def self.post(url, headers = {accept: "*/*"}, payload = "", user = "", pass="")  # username and password go into headers as user: xxx and password: yyy

		begin
			response = RestClient::Request.execute({
				method: :post,
				url: url.to_s,
				user: user,
				password: pass,
				payload: payload,
				headers: headers
			})
			return response
		rescue RestClient::ExceptionWithResponse => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue RestClient::Exception => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue Exception => e
			$stderr.puts e
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		end		  # you can capture the Exception and do something useful with it!\n",
	end
	
	def self.put(url, headers = {accept: "*/*"}, payload = "", user = "", pass="")  # username and password go into headers as user: xxx and password: yyy

	  
		begin
			response = RestClient::Request.execute({
				method: :put,
				url: url.to_s,
				user: user,
				password: pass,
				payload: payload,
				headers: headers
			})
			return response
		rescue RestClient::ExceptionWithResponse => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue RestClient::Exception => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue Exception => e
			$stderr.puts e
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		end		  # you can capture the Exception and do something useful with it!\n",
	end



	def self.delete(url, headers = {accept: "*/*"}, user = "", pass="") 
	  
		begin
			response = RestClient::Request.execute({
				method: :delete,
				url: url.to_s,
				user: user,
				password: pass,
				headers: headers
			})
			return response
		rescue RestClient::ExceptionWithResponse => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue RestClient::Exception => e
			$stderr.puts e.response
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		rescue Exception => e
			$stderr.puts e
			response = false
			return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
		end		  # you can capture the Exception and do something useful with it!\n",
	end

end

end
