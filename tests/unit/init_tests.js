

module.exports = function(options) {
	
	var rewire = require('rewire');
	var oauth_creator = rewire('../../js/main');
	var guid = function() {
		return 'unique_id';
	};
	oauth_creator.__set__('_guid', function () {
		return guid;
	});
	
	var OAuth = oauth_creator();
	var values = {
		OAuth: OAuth,
		guid: guid,
		express_app: require('./mocks/express.mock')()
	};
	return values;
};