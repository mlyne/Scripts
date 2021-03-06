# This file has been auto-generated by REST Compile. 
# 
# You should not modify it, unless you know what you do. Any modification 
# might cause serious damage, or even destroy your computer. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE. 
# 

# class auto-generated by REST Compile 
class RestRequest: 
	"""super class responsable for REST requests and error checks"""

	# init function 
	def __init__(self, ): 
		# provide user and password for HTTP AUTH 
		self.user = '' 
		self.password = '' 

	def do_get_call(self, uri): 
		"""the GET function""" 

		# HTTP related functions (urllib2 for error handling)
		import urllib2 
		import sys 
		import base64 

		request = urllib2.Request(uri) 

		# provide credentials if they're established 
		if self.user and self.password: 
			base64string = base64.encodestring('%s:%s' % (self.user, self.password))[:-1] 
			authheader =  "Basic %s" % base64string 
			request.add_header("Authorization", authheader) 

		try: 
			response = urllib2.urlopen(request).read() 
		except urllib2.HTTPError, e: 
 
			sys.exit("HTTP error: %d" % e.code) 
		except urllib2.URLError, e: 
			sys.exit("Network error: %s" % e.reason.args[1]) 

		return response 

	def do_post_call(self, uri, post_args): 
		"""the POST function""" 

		# HTTP related functions (urllib2 for error handling)
		import urllib2 
		import sys 
		import base64 

		request = urllib2.Request(uri) 

		# provide credentials if they're established 
		if self.user and self.password: 
			base64string = base64.encodestring('%s:%s' % (self.user, self.password))[:-1] 
			authheader =  "Basic %s" % base64string 
			request.add_header("Authorization", authheader) 

		try: 
			response = urllib2.urlopen(request, post_args).read() 
		except urllib2.HTTPError, e: 
 
			sys.exit("HTTP error: %d" % e.code) 
		except urllib2.URLError, e: 
			sys.exit("Network error: %s" % e.reason.args[1]) 

		return response 


# class auto-generated by REST Compile 
class Search(RestRequest): 
	"""request class responsable for creating a request object"""

	# init function 
	def __init__(self, q = None): 
		# initialize the super class 
		RestRequest.__init__(self, ) 

		# assign class variables 
		self.q = q
 
	# prepares the POST or GET parameters 
	def prepare_params(self): 
		import urllib 

		params = {} 

		# optional parameters
		if self.q:
			params['q'] =  self.q 

		return urllib.urlencode(params) 

	# submits the request 
	def submit(self): 

		request_uri = 'http://ops.epo.org/2.6.2/rest-services/published-data/search'

		return self.do_get_call(request_uri + '?' + self.prepare_params()) 


# class auto-generated by REST Compile 
class Search(RestRequest): 
	"""request class responsable for creating a request object"""

	# init function 
	def __init__(self, q = None, range = None): 
		# initialize the super class 
		RestRequest.__init__(self, ) 

		# assign class variables 
		self.q = q
		self.range = range
 
	# prepares the POST or GET parameters 
	def prepare_params(self): 
		import urllib 

		params = {} 

		# optional parameters
		if self.q:
			params['q'] =  self.q
		if self.range:
			params['range'] =  self.range 

		return urllib.urlencode(params) 

	# submits the request 
	def submit(self): 

		request_uri = 'http://ops.epo.org/2.6.2/rest-services/published-data/search'

		return self.do_get_call(request_uri + '?' + self.prepare_params()) 


