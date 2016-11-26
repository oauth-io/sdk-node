request = require 'request'
Q = require 'q'

module.exports = (csrf_generator, cache, requestio) ->
	a = {
		refresh_tokens: (credentials, session, force) ->
			defer = Q.defer()
			credentials.refreshed = false
			now = new Date()
			if credentials.refresh_token and ((credentials.expires and now.getTime() > credentials.expires) or force)
				request.post {
					url: cache.oauthd_url + cache.oauthd_base +  '/refresh_token/' + credentials.provider,
					form: {
						token: credentials.refresh_token,
						key: cache.public_key,
						secret: cache.secret_key
					}
				}, (e, r, body) ->
					if (e)
						defer.reject e
						return defer.promise
					else
						if typeof body is "string"
							try
								body = JSON.parse body
							catch e
								defer.reject e
							if typeof body == "object" and body.access_token and body.expires_in
								credentials.expires = new Date().getTime() + body.expires_in * 1000
								for k of body
									credentials[k] = body[k]
								if (session?)
									session.oauth = session.oauth || {}
									session.oauth[credentials.provider] = credentials
								credentials.refreshed = true
								credentials.last_refresh = new Date().getTime()
								defer.resolve credentials
							else
								defer.resolve credentials
			else
				defer.resolve credentials
			return defer.promise

		redirect: (provider, urlToRedirect, req, res, next) ->
			if cache.logging
				cache.log "[oauthio] Redirect to " + cache.oauthd_url + cache.oauthd_base + '/' + provider + " with k=" + cache.public_key + " and redirect_uri=" + urlToRedirect + " from " + (req.get && req.get('Host'))
			csrf_token = csrf_generator(req.session)
			res.writeHead 302, Location: cache.oauthd_url + cache.oauthd_base + '/' + provider + '?k=' + cache.public_key + '&opts=' + encodeURIComponent(JSON.stringify({state: csrf_token})) + '&redirect_type=server&redirect_uri=' + encodeURIComponent(urlToRedirect)
			res.end()
			next()

		auth: (provider, session, opts) ->
			defer = Q.defer()

			if typeof session == "function"
				return a.redirect provider, session

			if opts?.code
				return a.authenticate(opts.code, session)

			if opts?.credentials
				a.refresh_tokens(opts.credentials, session, opts?.force_refresh)
					.then (credentials) ->
						defer.resolve(a.construct_request_object(credentials))
				return defer.promise
			if (not opts?.credentials) and (not opts?.code)
				if session.oauth[provider]
					a.refresh_tokens(session.oauth[provider], session, opts?.force_refresh)
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
				url: cache.oauthd_url + cache.oauthd_base + '/access_token',
				form: {
					code: code,
					key: cache.public_key,
					secret: cache.secret_key
				}
			}, (e, r, body) ->
				doNext = ->
					if e
						defer.reject e
						return

					try
						response = JSON.parse body
					catch e
						defer.reject new Error 'OAuth.io response could not be parsed'
						return

					if cache.logging
						cache.hideInLog response.access_token if response.access_token
						cache.hideInLog response.id_token if response.id_token
						cache.hideInLog response.oauth_token if response.oauth_token
						cache.hideInLog response.oauth_token_secret if response.oauth_token_secret
						cache.hideInLog response.code if response.code
						cache.hideInLog response.state if response.state
						cache.log "[oauthio] From POST " + cache.oauthd_url + cache.oauthd_base + '/access_token (' + r.statusCode + '): ', body

					if (response.status? and response.status == 'error' and response.message?)
						defer.reject new Error 'OAuth.io / oauthd responded with : ' + response.message
					if (not response.state?)
						defer.reject new Error 'State is missing from response'
						return
					if (not session?.csrf_tokens? or response.state not in session.csrf_tokens)
						if cache.logging
							cache.log '[oauthio] State is not matching: "' + response.state + '" not in session (' + session?.oauthio_logging + '):', session?.csrf_tokens
						defer.reject new Error 'State is not matching'
					if response.expires_in
						response.expires = new Date().getTime() + response.expires_in * 1000
					response = a.construct_request_object response
					if (session?)
						session.oauth = session.oauth || {}
						session.oauth[response.provider] = response
					defer.resolve response
					return
				if (typeof session.reload) == 'function'
					session.reload doNext
				else
					cache.log '[oauthio] [warn] req.session should have a "reload" method'
					doNext()
			return defer.promise

	}
	return a
