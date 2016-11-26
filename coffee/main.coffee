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
	oauthd_url: 'https://oauth.io',
	oauthd_base: '/auth'
}

module.exports = ->
	guid = _guid()
	csrf_generator = _csrf_generator(guid, cache)
	requestio = _requestio(cache)
	authentication = _authentication(csrf_generator, cache, requestio)
	endpoints_initializer = _endpoints_initializer(csrf_generator, cache, authentication)

	cache.__hiddenLog = {}
	cache.__hiddenLogCount = 0
	cache.hideInLog = (hidden) ->
		if hidden and not (cache.logging and cache.logging.showAll)
			hidden = JSON.stringify(hidden)
			if not cache.__hiddenLog[hidden]
				cache.__hiddenLog[hidden] = ++cache.__hiddenLogCount
	cache.log = () ->
		if cache.logging?.silent
			return
		args = []
		for arg in arguments
			arg = JSON.stringify(arg) if (typeof arg) == 'object'
			arg = arg.toString()
			for k, v of cache.__hiddenLog
				arg = arg.replace k, "[hidden-" + v + "]"
			args.push arg
		console.log.apply(console, args)

	oauth =  {
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
				oauthd_url: 'https://oauth.io',
				oauthd_base: '/auth'
			}
		getAppKey: ->
			return cache.public_key
		getAppSecret: ->
			return cache.secret_key
		getCsrfTokens: (session) ->
			return session.csrf_tokens
		setOAuthdUrl: (url, base) ->
			cache.oauthd_url = url
			cache.oauthd_base = base if base
		setOAuthdURL: (url, base) ->
			return oauth.setOAuthdUrl(url, base)
		getOAuthdUrl: ->
			return cache.oauthd_url
		getOAuthdURL: ->
			return oauth.getOAuthdUrl()
		getVersion: ->
			package_info.version
		enableLogging: (options) ->
			cache.logging = options
			if (typeof cache.logging == "object") and cache.logging.showAll
				cache.log('[oauthio] Logging is enabled, these logs contains sensitive informations. Please, be careful before sharing them.')
			else
				cache.log('[oauthio] Logging is enabled.')
			cache.log('[oauthio] node ' + process.version + ', oauthio v' + package_info.version)
		generateStateToken: (session) ->
			csrf_generator(session)
		initEndpoints: (app) ->
			endpoints_initializer app
		auth: (provider, session, opts) ->
			if typeof opts == 'undefined' and typeof session == 'string'
				oauth.authRedirect provider, session
			else
				authentication.auth provider, session, opts

		redirect: (cb) ->
			return (req, res, next) ->
				if typeof req.query != 'object'
					return cb (new Error "req.query must be an object (did you used a query parser?)"), req, res
				if typeof req.query.oauthio == 'undefined'
					return cb (new Error "Could not find oauthio in query string"), req, res
				try
					oauthio_data = JSON.parse req.query.oauthio
					if cache.logging
						if (oauthio_data.data)
							cache.hideInLog oauthio_data.data.id_token if oauthio_data.data.id_token
							cache.hideInLog oauthio_data.data.access_token if oauthio_data.data.access_token
							cache.hideInLog oauthio_data.data.oauth_token if oauthio_data.data.oauth_token
							cache.hideInLog oauthio_data.data.oauth_token_secret if oauthio_data.data.oauth_token_secret
							cache.hideInLog oauthio_data.data.code if oauthio_data.data.code
							cache.hideInLog oauthio_data.data.state if oauthio_data.data.state
						cache.log '[oauthio] Redirect received from ' + (req.get && req.get('Host')), oauthio_data
				catch error
					return cb (new Error "Could not parse oauthio results"), req, res
				if oauthio_data.status == "error"
					return cb (new Error (oauthio_data.message || "Authorization error")), req, res
				if not oauthio_data.data?.code
					return cb (new Error "Could not find code from oauthio results"), req, res
				authentication.authenticate(oauthio_data.data.code, req.session)
					.then((r) ->
						cb r, req, res, next
					)
					.fail((e) ->
						cb e, req, res, next
					)

		authRedirect: (provider, urlToRedirect) ->
			return (req, res, next) ->
				if typeof req.session != 'object' && typeof next == 'function'
					return next new Error "req.session must be an object (did you used a session middleware?)"
				authentication.redirect provider, urlToRedirect, req, res, next
				return

		refreshCredentials: (credentials, session) ->
			return authentication.refresh_tokens credentials, session, true
	}
	return oauth;