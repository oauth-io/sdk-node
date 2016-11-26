var endpoints = [];
var events = require('events');
var emitter = new events.EventEmitter();
var session = {
	reload: (cb) => cb()
};
module.exports = function() {
	return {
		getEndpoint: function(url) {
			return endpoints[url];
		},
		get: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['GET ' + url] = arguments;
		},
		post: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['POST ' + url] = arguments;
		},
		patch: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['PATCH ' + url] = arguments;
		},
		opts: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['OPTIONS ' + url] = arguments;
		},
		del: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['DELETE ' + url] = arguments;
		},
		put: function() {
			var url = arguments[0];
			arguments = Array.prototype.slice.call(arguments);
			arguments.shift();
			endpoints['PUT ' + url] = arguments;
		},
		addSendHandler: function(handler) {
			emitter.once('send.called', handler);
		},
		res: {
			send: function() {
				arguments = Array.prototype.slice.call(arguments);
				arguments.unshift('send.called');
				emitter.emit.apply(emitter, arguments);
			}
		},
		req: {
			session: session
		},
		getSession: function() {
			return this.req.session();
		},
		callEndpoint: function(url, params, i) {
			var base = this;

			i = i || 0;
			params = params || {};
			params.method = params.method || 'GET';
			var endpoint = endpoints[params.method + ' ' + url];
			if (endpoint) {
				if (endpoint[i]) {
					var _req = {};
					for (var k in this.req) {
						_req[k] = this.req[k]
					}
					for (var k in params) {
						_req[k] = params[k]
					}
					endpoint[i](_req, this.res, function() {
						base.call.apply(base, [url, params, i + 1]);
					});
				}
			} else {
				throw new Error('no endpoint');
			}
		}
	};
};