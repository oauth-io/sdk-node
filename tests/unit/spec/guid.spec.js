var values = {};
var guid = require('../../../js/tools/guid')();
describe("CSRF Token generation (guid)", function () {
	it ("guid() should return a string like 5b75d7-6cb-007-63-1855a21", function () {
		expect(guid()).toMatch(/^[0-9a-z]+-[0-9a-z]+-[0-9a-z]+-[0-9a-z]+-[0-9a-z]+$/);
	});
});