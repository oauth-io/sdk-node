module.exports = (guid) -> 
	return (req) ->
		csrf_token = guid()
		req.session.csrf_tokens = req.session.csrf_tokens or []
		req.session.csrf_tokens.push csrf_token
		req.session.csrf_tokens.shift()  if req.session.csrf_tokens.length > 4
		return csrf_token