var values = {};
var qs = require('querystring');
var nock = require('nock');
describe('Token refresh', function() {
	var credentials = {};
	beforeEach(function(done) {
		values = require('../init_tests')();
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

		values.OAuth.auth('google', values.express_app.req.session, {
			code: 'somecode'
		})
			.then(function(result) {
				credentials = result.getCredentials();
				expect(result.access_token).toBe('result_access_token');
				done();
			})
			.fail(function(error) {
				expect(error).not.toBeDefined();
				done();
			});
	});

	it('OAuth.refreshCredentials() should refresh a set of credentials through oauth.io/auth/refresh_token', function (done) {
		var scope = nock('https://oauth.io')
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

		values.OAuth.refreshCredentials(credentials)
			.then(function (credentials) {
				expect(credentials).toBeDefined();
				expect(credentials.access_token).toBe('new_access_token');
				expect(credentials.refresh_token).toBe('new_refresh_token');
				expect(credentials.expires).toBeGreaterThan(new Date().getTime() + 1000000);
				done();
			})
			.fail(function (e) {
				expect(true).toBe(false);
				done();
			});
	});
});