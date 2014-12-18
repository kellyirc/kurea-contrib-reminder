unitMap =
	millisecond: 1
	second: 1000
	minute: 60*1000
	hour: 60*60*1000
	day: 24*60*60*1000

	atom: 160
	pahar: 3 * 60 * 60 * 1000
	week: 7 * 24 * 60 * 60 * 1000
	fortnight: 14 * 24 * 60 * 60 * 1000
	lunarday: 2551443000
	month: 30 * 24 * 60 * 60 * 1000
	year: 365 * 24 * 60 * 60 * 1000
	moment: 90 * 1000
	chelek: 3333
	rega: 43
	jiffy: 17
	decade: 10 * 365 * 24 * 60 * 60 * 1000
	century: 100 * 365 * 24 * 60 * 60 * 1000
	millennium: 1000 * 365 * 24 * 60 * 60 * 1000
	microfortnight: 1209
	instant: 0

aliases =
	millisecond: ['milliseconds', 'ms', 'msec']
	second: ['seconds', 's', 'sec']
	minute: ['minutes', 'm', 'min']
	hour: ['hours', 'h']
	day: ['days', 'd']

	atom: ['atoms']
	pahar: ['pahars', 'paher', 'pahers']
	week: ['weeks', 'w', 'sennight', 'sennights']
	fortnight: ['fortnights']
	lunarday: ['lunardays']
	month: ['months']
	year: ['years', 'y']
	moment: ['moments']
	chelek: ['cheleks']
	rega: ['regas']
	jiffy: ['jiffys', 'jiffies']
	decade: ['decades']
	century: ['centuries', 'centurys']
	millennium: ['millenniums', 'millennia']
	microfortnight: ['microfortnights']
	instant: ['instants']

for key, aliasList of aliases
	unitMap[alias] = unitMap[key] for alias in aliasList

isUnit = (unit) ->
	unit of unitMap

toMs = (unit, amount = 1) ->
	amount * unitMap[unit]

module.exports = {isUnit, toMs}