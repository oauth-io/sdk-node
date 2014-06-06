module.exports = (guid) -> 
	return (session) ->
		csrf_token = guid()
		session.csrf_tokens = session.csrf_tokens or []
		session.csrf_tokens.push csrf_token
		session.csrf_tokens.shift()  if session.csrf_tokens.length > 4
		return csrf_token