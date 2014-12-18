_ = require 'underscore'

unitMap =
	millisecond: 1
	second: 1000
	minute: 60*1000
	hour: 60*60*1000
	day: 24*60*60*1000

aliases =
	millisecond: ['milliseconds', 'ms', 'msec']
	second: ['seconds', 's', 'sec']
	minute: ['minutes', 'm', 'min']
	hour: ['hours', 'h']
	day: ['days', 'd']

for key, aliasList of aliases
	unitMap[alias] = unitMap[key] for alias in aliasList

unitList = Object.keys unitMap

class ReminderParser
	constructor: (text) ->
		@tokens = text.split /\s+/
		console.log @tokens

	peekToken: (offset = 0) -> @tokens[offset]

	pullToken: -> @tokens.shift()

	parse: ->
		target = @pullToken()
		time = null
		rest = []
		task = null

		while @peekToken()?
			if @isIn() then time = @parseIn()

			else rest.push @pullToken()

		if rest[0] is 'to' then task = rest[1..].join ' '

		{target, time, task}

	isIn: ->
		_.all [
			(@peekToken 0) is 'in'
			@isTimeAmount 1
		]

	parseIn: ->
		@pullToken() # 'in'

		total = 0
		(total += @parseTimeAmount()) while @isTimeAmount()
		total

	isTimeAmount: (offset = 0) ->
		_.all [
			(Number @peekToken offset) isnt NaN
			(@peekToken offset+1) in unitList
		]

	parseTimeAmount: ->
		amount = Number @pullToken() # amount
		unit = @pullToken() # unit

		amount * unitMap[unit]

module.exports = exports = (text) ->
	parser = new ReminderParser text
	
	parser.parse()