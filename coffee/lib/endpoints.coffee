qs = require 'querystring'

module.exports = (csrf_generator, cache, authentication) ->
	return (app) ->
		app.get '/oauth/csrf_token', (req, res) =>
			csrf_token = csrf_generator(req)
			res.send 200, csrf_token
		app.post '/oauth/authenticate', (req, res) =>
			authentication.authenticate((qs.parse req.body).code, req)
				.then((r) ->
					
					res.send 200, 'Successfully authenticated'
				)
				.fail((e) ->
					res.send 400, 'An error occured during authentication'
				)
				