_guid = require('./tools/guid')
_csrf_generator = require('./lib/csrf_generator')
_endpoints_initializer = require('./lib/endpoints')
_authentication = require('./lib/authentication')
_requestio = require('./lib/request')
package_info = require('../package.json')

cache = {
	public_key: undefined,
	secret_key: undefined,
	csrf_tokens: [],
	oauthd_url: 'https://oauth.io'
}

module.exports = ->
	

	guid = _guid()
	csrf_generator = _csrf_generator(guid)
	requestio = _requestio(cache)
	authentication = _authentication(cache, requestio)
	endpoints_initializer = _endpoints_initializer(csrf_generator, cache, authentication)

	
	
	return {
		initialize: (app_public_key, app_secret_key) ->
			cache.public_key = app_public_key
			cache.secret_key = app_secret_key
		__getCache: ->
			return cache
		__clearCache: ->
			cache = {
				public_key: undefined,
				secret_key: undefined,
				csrf_tokens: [],
				oauthd_url: 'https://oauth.io'
			}
		getAppKey: ->
			return cache.public_key
		getAppSecret: ->
			return cache.secret_key
		getCsrfTokens: (req) ->
			return req.session.csrf_tokens
		setOAuthdUrl: (url) ->
			cache.oauthd_url = url
		getOAuthdUrl: ->
			return cache.oauthd_url
		getVersion: ->
			package_info.version
		generateCSRFToken: (req) ->
			csrf_generator(req)
		initEndpoints: (app) ->
			endpoints_initializer app
		auth: (code, req) ->
			authentication.authenticate code, req
		create: (req, provider_name) ->
			response = req?.session?.oauth?[provider_name]
			if not response?
				response = {
					error: true
					provider: provider_name
				}

			response.get = (url) ->
				return requestio.make_request(response, 'GET', url)
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
			return response
	}
	