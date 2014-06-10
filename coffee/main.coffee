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
		getCsrfTokens: (session) ->
			return session.csrf_tokens
		setOAuthdUrl: (url) ->
			cache.oauthd_url = url
		getOAuthdUrl: ->
			return cache.oauthd_url
		getVersion: ->
			package_info.version
		generateStateToken: (session) ->
			csrf_generator(session)
		initEndpoints: (app) ->
			endpoints_initializer app
		auth: (provider, session, opts) ->
			authentication.auth provider, session, opts
		refreshCredentials: (credentials, session) ->
			return authentication.refresh_tokens credentials, session, true
	}
	