deps = {
	__set: (obj) ->
		for k of obj
			deps.container[k] = obj[k]
		return
	reset: {}
	container: {}
}

module.exports = deps