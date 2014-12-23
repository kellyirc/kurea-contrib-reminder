_ = require 'underscore'
_.str = require 'underscore.string'

module.exports = (time) ->
	timeParts =
		y: Math.floor(time / (365*24*60*60*1000))
		d: Math.floor(time / (24*60*60*1000)) % 365
		h: Math.floor(time / (60*60*1000)) % 24
		m: Math.floor(time / (60*1000)) % 60
		s: Math.floor(time / 1000) % 60
		ms: time % 1000

	units =
		y: ["year", "years"]
		d: ["day", "days"]
		h: ["hour", "hours"]
		m: ["minute", "minutes"]
		s: ["second", "seconds"]
		ms: ["millisecond", "milliseconds"]

	parts = []
	for unit, amnt of timeParts
		if amnt is 0 then continue

		plural = if amnt is 1 then 0 else 1
		parts.push "#{amnt} #{units[unit][plural]}"

	_.str.toSentence parts