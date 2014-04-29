var values = {};

describe('OAuth.setOAuthdUrl', function () {
	beforeEach(function () {
		values = require('../init_tests')();
	});

	afterEach(function () {
		values.OAuth.setOAuthdUrl('https://oauth.io');
	});

	it('should exist', function () {
		expect(typeof values.OAuth.setOAuthdUrl).toBe('function');
	});

	it ('should let the developer change the oauthd url', function () {
		expect(typeof values.OAuth.getOAuthdUrl).toBe('function');
		expect(values.OAuth.getOAuthdUrl()).toBe('https://oauth.io');
		values.OAuth.setOAuthdUrl('https://myownurl');
		expect(values.OAuth.getOAuthdUrl()).toBe('https://myownurl');
	});
});