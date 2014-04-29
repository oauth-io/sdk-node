var values = {};

describe('OAuth.getVersion', function () {
	beforeEach(function () {
		values = require('../init_tests')();
	});

	it('should exist', function () {
		expect(typeof values.OAuth.getVersion).toBe('function');
	});

	it ('should return the current version of the SDK', function () {
		expect(values.OAuth.getVersion()).toBe(require('../../../package.json').version);
	})
});