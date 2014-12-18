_ = require 'underscore'

units = require './units'

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
			units.isUnit @peekToken offset+1
		]

	parseTimeAmount: ->
		amount = Number @pullToken() # amount
		unit = @pullToken() # unit

		units.toMs unit, amount

module.exports = exports = (text) ->
	parser = new ReminderParser text
	
	parser.parse()