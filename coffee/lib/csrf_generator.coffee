module.exports = (guid, cache) ->
	logging_sessionCount = 0
	return (session) ->
		csrf_token = guid()
		session.csrf_tokens = session.csrf_tokens or []
		session.csrf_tokens.push csrf_token
		session.csrf_tokens.shift()  if session.csrf_tokens.length > 4
		if cache.logging
			if not session.oauthio_logging
				session.oauthio_logging = ++logging_sessionCount
			cache.hideInLog csrf_token
			cache.log '[oauthio] Add csrf token "' + csrf_token + '" to session (' + session.oauthio_logging + ')'
		return csrf_token