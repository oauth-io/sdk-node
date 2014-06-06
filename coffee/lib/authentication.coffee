request = require 'request'
Q = require 'q'

module.exports = (cache, requestio) ->
	a = {
		refresh_tokens: (credentials, force) ->
			defer = Q.defer()
			# call refresher here
			defer.resolve credentials
			# set credentials.refreshed to true if refreshed
			return defer.promise
		auth: (provider, session, opts) ->
			defer = Q.defer()

			if opts?.code
				return a.authenticate(opts.code, session)

			if opts?.credentials
				a.refresh_tokens(opts.credentials, opts?.force_refresh)
					.then (credentials) ->
						defer.resolve(a.construct_request_object(credentials))
				return defer.promise
			if (not opts?.credentials) and (not opts?.code)
				if session.oauth[provider]
					a.refresh_tokens(session.oauth[provider], opts?.force_refresh)
						.then (credentials) ->
							defer.resolve(a.construct_request_object(credentials))
				else
					defer.reject new Error('Cannot authenticate from session for provider \'' + provider + '\'')
				return defer.promise

			defer.reject new Error('Could not authenticate, parameters are missing or wrong')
			return defer.promise
		construct_request_object: (credentials) ->
			request_object = {}
			for k of credentials
				request_object[k] = credentials[k]
			request_object.get = (url, options) ->
				return requestio.make_request(request_object, 'GET', url, options)
			request_object.post = (url, options) ->
				return requestio.make_request(request_object, 'POST',url, options)
			request_object.patch = (url, options) ->
				return requestio.make_request(request_object, 'PATCH', url, options)
			request_object.put = (url, options) ->
				return requestio.make_request(request_object, 'PUT', url, options)
			request_object.del = (url, options) ->
				return requestio.make_request(request_object, 'DELETE', url, options)
			request_object.me = (options) ->
				return requestio.make_me_request(request_object, options)
			request_object.getCredentials = () ->
				return credentials
			request_object.wasRefreshed = () ->
				return credentials.refreshed
			return request_object
		authenticate: (code, session) -> 
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
				if (not session?.csrf_tokens? or response.state not in session.csrf_tokens)
					defer.reject new Error 'State is not matching'

				response = a.construct_request_object response
				if (session?)
					session.oauth = session.oauth || {}
					session.oauth[response.provider] = response
				defer.resolve response
			return defer.promise

	}
	return a
