var values = {};

describe('generateCSRFToken', function () {
	beforeEach(function () {
		values = require('../init_tests')();
	});

	it ('should create a unique id and store it in the session', function () {

		expect(values.OAuth.generateCSRFToken).toBeDefined();
		expect(typeof values.OAuth.generateCSRFToken).toBe('function');

		var token = values.OAuth.generateCSRFToken(values.express_app.req);

		expect(typeof token).toBe('string');
		expect(typeof values.express_app.req.session.csrf_tokens).toBe('object');
		expect(typeof values.express_app.req.session.csrf_tokens.length).toBe('number');

		expect(values.express_app.req.session.csrf_tokens.indexOf(token)).not.toBe(-1);
	});
});