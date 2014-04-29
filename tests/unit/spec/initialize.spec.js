var values = {};

describe('OAuth.initialize', function () {
	beforeEach(function () {
		values = require('../init_tests')();
	});

	it('should exist', function () {
		expect(typeof values.OAuth.initialize).toBe('function');
	});

	it ('should store the app key and its secret inside a cache', function () {
		values.OAuth.initialize('hellow', 'people');
		expect(values.OAuth.getAppKey()).toBe('hellow');
		expect(values.OAuth.getAppSecret()).toBe('people');
	});
});