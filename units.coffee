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

isUnit = (unit) ->
	unit of unitMap

toMs = (unit, amount = 1) ->
	amount * unitMap[unit]

module.exports = {isUnit, toMs}