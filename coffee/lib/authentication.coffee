request = require 'request'
Q = require 'q'

module.exports = (cache, requestio) ->
	return {
		authenticate: (code, req) -> 
			defer = Q.defer()
			request.post {
				url: cache.oauthd_url + '/auth/access_token',
				form: {
					code: code,
					key: cache.public_key,
					secret: cache.secret_key
				}
			}, (e, r, body) ->
				if e
					defer.reject e
					return

				try
					response = JSON.parse body
				catch e
					defer.reject new Error 'OAuth.io response could not be parsed'
					return

				if (not response.state?)
					defer.reject new Error 'State is missing from response'
					return

				if (not req?.session?.csrf_tokens? or response.state not in req.session.csrf_tokens)
					defer.reject new Error 'State is not matching'

				response.get = (url, options) ->
					return requestio.make_request(response, 'GET', url, options)
				response.post = (url, options) ->
					return requestio.make_request(response, 'POST',url, options)
				response.patch = (url, options) ->
					return requestio.make_request(response, 'PATCH', url, options)
				response.put = (url, options) ->
					return requestio.make_request(response, 'PUT', url, options)
				response.del = (url, options) ->
					return requestio.make_request(response, 'DELETE', url, options)
				response.me = (options) ->
					return requestio.make_me_request(response, options)
				if (req?.session?)
					req.session.oauth = req.session.oauth || {}
					req.session.oauth[response.provider] = response
				defer.resolve response
			return defer.promise
	}
