/**
 * The initEndpoints method must be given an 'app' object from express
 * or restify.
 * If it is not called, the developer must handle the endpoints himself,
 * using the default ones, or his own (in that cas he must set the URLs
 * in the front SDK).
 */
var values = {};
var nock = require('nock');
var qs = require('querystring');

describe('OAuth endpoints initialization', function() {
	beforeEach(function() {
		values = require('../init_tests')();
		values.OAuth.initialize('somekey', 'somesecret');
	});
	it('OAuth.initEndpoints should exist', function() {
		expect(values.OAuth.initEndpoints).toBeDefined();
		expect(typeof values.OAuth.initEndpoints).toBe('function');
	});
	it('OAuth.initEndpoints should initialize a get endpoint for the CSRF_TOKEN on /oauth/csrf_token', function() {
		values.OAuth.initEndpoints(values.express_app);
		var endpoint = values.express_app.getEndpoint('GET /oauth/csrf_token');
		expect(endpoint).toBeDefined();
		expect(endpoint.length).toBeDefined();
		expect(endpoint.length).toBe(1);
	});

	it('The generated endpoint /oauth/csrf_token should call the guid method and return its result', function(done) {
		values.OAuth.initEndpoints(values.express_app);
		var endpoint = values.express_app.getEndpoint('GET /oauth/csrf_token');
		expect(endpoint).toBeDefined();
		var calls_done = function(status, result) {
			expect(status).toBe(200);
			expect(result).toBe('unique_id');
			expect(values.express_app.req.session.csrf_tokens).toBeDefined();
			expect(typeof values.express_app.req.session.csrf_tokens).toBe('object');
			expect(values.express_app.req.session.csrf_tokens[0]).toBe('unique_id');
			done();
		};

		values.express_app.addSendHandler(function() {
			var params = Array.prototype.slice.call(arguments);
			calls_done.apply(this, params);
		});

		values.express_app.callEndpoint('/oauth/csrf_token', {
			method: 'GET'
		});
	});

	it('OAuth.initEndpoint should initialize a POST endpoint for the access_token on /oauth/authenticate', function() {
		values.OAuth.initEndpoints(values.express_app);
		var endpoint = values.express_app.getEndpoint('POST /oauth/authenticate');
		expect(endpoint).toBeDefined;
		expect(endpoint.length).toBeDefined();
		expect(endpoint.length).toBe(1);
	});

	it('The generated endpoint /oauth/authenticate should authenticate on oauth.io.', function(done) {
		values.OAuth.initEndpoints(values.express_app);
		values.OAuth.generateStateToken(values.express_app.req);
		var endpoint = values.express_app.getEndpoint('POST /oauth/authenticate');
		expect(endpoint).toBeDefined();

		var calls_done = function(status, result) {
			expect(status).toBe(200);
			expect(typeof result).toBe('string');
			expect(result).toBeDefined();
			expect(result).toBe('Successfully authenticated');
			done();
		};

		values.express_app.addSendHandler(function() {
			var params = Array.prototype.slice.call(arguments);
			calls_done.apply(this, params);
		});

		var scope = nock('https://oauth.io')
			.post('/auth/access_token', {
				code: 'somecode',
				key: 'somekey',
				secret: 'somesecret'
			})
			.reply(200, {
				access_token: 'result_access_token',
				expires_in: 'someday',
				request: {},
				state: 'unique_id',
				provider: 'facebook'
			});

		values.express_app.callEndpoint('/oauth/authenticate', {
			method: 'POST',
			body: qs.stringify({
				code: 'somecode'
			})
		});
	});

	it('The generated endpoint /oauth/authenticate should throw 400 An error occured during authentication on error', function(done) {
		values.OAuth.initEndpoints(values.express_app);
		values.OAuth.generateStateToken(values.express_app.req);
		var endpoint = values.express_app.getEndpoint('POST /oauth/authenticate');
		expect(endpoint).toBeDefined();

		var calls_done = function(status, result) {
			expect(status).toBe(400);
			expect(typeof result).toBe('string');
			expect(result).toBeDefined();
			expect(result).toBe('An error occured during authentication');
			done();
		};

		values.express_app.addSendHandler(function() {
			var params = Array.prototype.slice.call(arguments);
			calls_done.apply(this, params);
		});

		var scope = nock('https://oauth.io')
			.post('/auth/access_token', {
				code: 'somecode',
				key: 'somekey',
				secret: 'somesecret'
			})
			.reply(400, {
				access_token: 'result_access_token',
				expires_in: 'someday',
				request: {},
				provider: 'facebook'
			});

		values.express_app.callEndpoint('/oauth/authenticate', {
			method: 'POST',
			body: qs.stringify({
				code: 'somecode'
			})
		});
	});

});