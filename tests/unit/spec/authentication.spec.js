var nock = require('nock');

var values = {};

describe("OAuth authentication", function() {
	beforeEach(function() {
		values = require('../init_tests')();
	});

	it("should be able to send the code to an oauthd instance in exchange for an access token", function(done) {
		values.OAuth.initialize('somekey', 'somesecret');
		values.OAuth.generateStateToken(values.express_app.req.session);
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

		values.OAuth.auth('facebook', values.express_app.req.session, {
			code: 'somecode'
		})
		.then(function(result) {
			expect(result.access_token).toBe('result_access_token');
			done();
		})
		.fail(function(error) {
			console.log(error);
			expect(error).not.toBeDefined();
			done();
		});
	});

	it("should throw 'State is missing from response' when state is not returned", function(done) {
		values.OAuth.initialize('somekey', 'somesecret');
		values.OAuth.generateStateToken(values.express_app.req.session);
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
				provider: 'facebook'
			});

		values.OAuth.auth('facebook', values.express_app.req.session, {
			code: 'somecode'
		})
		.then(function(result) {
			expect(result).not.toBeDefined();
			done();
		})
		.fail(function(error) {
			expect(error).toBeDefined();
			expect(error.message).toBe('State is missing from response');
			done();
		});
	});

	it("should throw 'State is not matching' when state from response is not matching a state in cache", function(done) {
		values.OAuth.initialize('somekey', 'somesecret');
		values.OAuth.generateStateToken(values.express_app.req.session);
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
				state: 'wrongstate',
				provider: 'facebook'
			});

		values.OAuth.auth('facebook', values.express_app.req.session, {
			code: 'somecode'
		})
		.then(function(result) {
			expect(result).not.toBeDefined();
			done();
		})
		.fail(function(error) {
			expect(error).toBeDefined();
			expect(error.message).toBe('State is not matching');
			done();
		});
	});

	it("should throw 'State is not matching' when state from response is not matching a state in cache", function(done) {


		values.OAuth.initialize('somekey', 'somesecret');
		values.OAuth.generateStateToken(values.express_app.req.session);
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
				provider: 'google',
				refresh_token: 'the_refresh_token',
				expires_in: 1,
				token_type: 'Bearer'
			});
		var scope2 = nock('https://oauth.io')
				.post('/auth/refresh_token/google', {
					token: 'the_refresh_token',
					key: 'somekey',
					secret: 'somesecret'
				})
				.reply(200, {
					access_token: 'new_access_token',
					refresh_token: 'new_refresh_token',
					expires_in: 3600,
					token_type: 'Bearer'
				});

		values.OAuth.auth('google', values.express_app.req.session, {
			code: 'somecode'
		})
		.then(function(result) {
			expect(result.access_token).toBe('result_access_token');
			return values.OAuth.auth('google', values.express_app.req.session, {
				force_refresh: true
			});
		})
		.then(function(request_object) {
			expect(request_object.wasRefreshed()).toBe(true);
			done();
		})
		.fail(function(error) {
			expect(error).not.toBeDefined();
			done();
		});
	});
});