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
});