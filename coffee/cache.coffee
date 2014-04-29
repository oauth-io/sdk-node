cache = {
	__set: (obj) ->
		for k of obj
			@[k] = obj[k]
		return
}

module.exports = cache