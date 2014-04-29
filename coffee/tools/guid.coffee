module.exports = () ->
	->
		s4 = ->
			return (Math.floor(1 + Math.random() * 10000)).toString(16).substring(1)
		return s4() + s4() + '-' + s4() + '-' + s4() + '-'+
			 s4() + '-' + s4() + s4() + s4()
