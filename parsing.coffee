unitMap =
	second: 1000
	minute: 60*1000
	hour: 60*60*1000
	day: 24*60*60*1000

aliases =
	second: ['seconds', 's', 'sec']
	minute: ['minutes', 'm', 'min']
	hour: ['hours', 'h']
	day: ['days', 'd']

for key, aliasList of aliases
	unitMap[alias] = unitMap[key] for alias in aliasList

unitList = Object.keys unitMap

tokens =
	space:
		matching: /\s+/g
		hidden: yes

	number:
		matching: /\d+(\.\d+)?/g
		value: (t) -> Number t.text

	word:
		matching: /\w+/g

class Lexer
	constructor: (@tokenMap) ->

	lex: (text) ->
		tokens = []
		currentPosition = 0

		while currentPosition < text.length
			token = null
			for tokenName, tokenDef of @tokenMap
				token = @matchToken text, currentPosition,
					name: tokenName
					def: tokenDef

				if token? then break

			if token?
				# console.log "Got token: #{token.text} (#{token.type})"
				tokens.push token if not @tokenMap[token.type].hidden
				currentPosition = token.end
			else
				throw new Error "Unexpected symbol #{text.charAt(currentPosition)}"

		tokens

	matchToken: (text, currentPosition, tokenDef) ->
		# console.log "Current symbol: #{text.charAt(currentPosition)}"
		# console.log "Now handling", (text.charAt(i) for i in [Math.max(currentPosition-3, 0)..Math.min(currentPosition+3, text.length-1)]), "as", tokenDef.name

		if tokenDef.def.matching instanceof RegExp
			tokenDef.def.matching.lastIndex = currentPosition

			match = tokenDef.def.matching.exec text
			# console.log "Matched! #{match[0]}; #{match.index}" if match?
			if match? and match.index is currentPosition
				# console.log match
				groups = []

				while match[groups.length]?
					groups.push match[groups.length]

				return @makeToken tokenDef, match[0], currentPosition, groups

		else if tokenDef.def.matching instanceof Array
			for item in tokenDef.def.matching
				if item is text.substring currentPosition, currentPosition+item.length
					return @makeToken tokenDef, item, currentPosition

		else if typeof tokenDef.def.matching is 'string'
			if tokenDef.def.matching is text.substring currentPosition, currentPosition+tokenDef.def.matching.length
				return @makeToken tokenDef, tokenDef.def.matching, currentPosition

	makeToken: (tokenDef, text, position, groups) ->
		token =
			type: tokenDef.name
			text: text
			start: position
			end: position + text.length

		if groups? then token.groups = groups

		if tokenDef.def.value?
			token.value = tokenDef.def.value token

		token

class Parser
	constructor: (@lexer, text) ->
		@currentPos = 0
		@tokens = @lexer.lex text

	hasNext: ->
		@currentPos < @tokens.length

	peek: (n = 0) ->
		@tokens[@currentPos+n]

	next: ->
		t = @tokens[@currentPos]
		@currentPos += 1
		t

	check: (token, expected) ->
		return (expected is null) if not token?

		token? and token.type is expected

	assert: (token, expected) ->
		if not @check token, expected
			throw new Error "Expected token type '#{expected}', got '#{token?.type ? 'undefined'}'"
		token

class ReminderParser extends Parser
	parse: ->
		r = {}

		# Parse target
		r.target = @parseTarget()

		# Parse parts
		#   in ...
		#   to ...
		until r.time? and r.task?
			if @isIn() and not r.time?
				r.time = @parseIn()

			else if @isTo() and not r.task?
				r.task = @parseTo()

			else
				throw new Error "Unrecognized text '#{@peek(0).text}'"

		# Make sure we've reached end of input
		@assert @next(), null

		r

	checkText: (token, expected) ->
		@check(token, 'word') and token.text is expected

	assertText: (token, expected) ->
		@assert(token, 'word')

		if not @checkText token, expected
			throw new Error "Expected token text '#{expected}', got '#{token.text}'"

		token

	parseTarget: ->
		(@assert @next(), 'word').text

	isIn: ->
		(@checkText @peek(0), 'in') and (@check @peek(1), 'number') and (@check @peek(2), 'word') and (@peek(2).text in unitList)

	parseIn: ->
		@assertText @next(), 'in'

		totalTime = 0
		while (@check @peek(0), 'number') and (@check @peek(1), 'word') and (@peek(1).text in unitList)
			time = @next()
			unit = @next()

			console.log "Parsed '#{time.text}' '#{unit.text}'"
			totalTime += time.value * unitMap[unit.text]

		totalTime

	isTo: ->
		(@checkText @peek(0), 'to') and (not @check @peek(1), null)

	parseTo: ->
		@assertText @next(), 'to'

		parts = []
		until (@check @peek(0), null) or @isIn()
			parts.push @next().text

		parts.join ' '

module.exports = exports = (text) ->
	l = new Lexer tokens
	p = new ReminderParser l, text
	data = p.parse()

exports.unitMap = unitMap
exports.aliases = aliases
exports.unitList = unitList
exports.tokens = tokens
exports.Lexer = Lexer
exports.Parser = Parser
exports.ReminderParser = ReminderParser