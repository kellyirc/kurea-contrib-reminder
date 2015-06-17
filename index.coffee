module.exports = (Module) ->
	_ = require 'underscore'

	# {Lexer, Parser, ReminderParser} = require './parsing'
	parseReminder = require './parsing'
	formatTime = require './time-format'

	# The back-in-time lines!
	backInTimeLines = [
		"You think this is *%#@ing Back To The Future?"
		"What the *%#@ do you think this is? Steins;Gate?"
		"Flux Capacitors are yet to be mass-produced..."
		"Yeah, I'll just, y'know, totally send you a message back in time. Not a problem."
		"You're supposed to specify sometime in the future, not the past!"
		"ERROR: Unable to send D-Mail: Lifter is missing"
		"Phone Microwave currently out of function, cannot send D-Mail"
		"If I could time travel, I'd remind <%= target %> to <%= task %> <%= time %> ago. But I can't!"
		"Yeah, sure, remind <%= target %> to <%= task %> <%= time %> ago, because I TOTALLY can send messages back in time!"
		"This is just awfully silly of you."
		"I don't even know what to say."
		"I suppose you don't have any device that can send messages back in time? Because I don't."
	]
	
	lowerFunc = (func) -> (str) -> func(str.toLowerCase());
	pronounConversions =
		'\\b(myself|yourself)\\b': lowerFunc (match) -> if match is 'myself' then 'yourself' else 'myself'
		'\\b(yours|mine)\\b': lowerFunc (match) -> if match is 'yours' then 'mine' else 'yours'
		'\\b(your|my)\\b': lowerFunc (match) -> if match is 'your' then 'my' else 'your'
		'\\b(i|me|you)\\b': lowerFunc (match) -> if (match is 'i' or match is 'me') then 'you' else 'me'
		'\\b(am|are)\\b': lowerFunc (match) -> if match is 'am' then 'are' else 'am'

	class ReminderModule extends Module
		shortName: "Reminder"
		
		helpText:
			default: "Set a reminder for some period of time!"
		usage:
			default: "remind [user|me] in [timeframe] to [task]"
	
		constructor: (moduleManager) ->
			super(moduleManager)
	
			@reminders = []
	
			@db = @newDatabase 'reminders'
	
			@db.find {}, (err, docs) =>
				return console.error err.stack if err?

				@startReminder doc for doc in docs
	
			@addRoute 'remind :args', (origin, route) =>
				{args} = route.params

				try
					data = parseReminder @stripPunctuation args
					if data.time < 0
						compiled = _.template _.sample backInTimeLines

						templateData =
							target: if data.own then 'you' else data.target
							task: data.task
							time: formatTime -data.time

						@reply origin, compiled(templateData)

						return

					data.endTime = Date.now() + data.time

					data.own = (data.target is 'me' or data.target is origin.user)
					data.target = origin.user if data.target is 'me'

					for original, replacement of pronounConversions
						data.task = data.task.replace new RegExp(original, 'gi'), replacement
						console.log new RegExp(original).test data.task
	
					data.botName = origin.bot.getName()
	
					@reply origin, "Alright, I'll remind #{if data.own then 'you' else data.target} to '#{data.task}' in #{formatTime data.time}!"
					console.log data
	
					@db.insert data, (err, data) =>
						if err?
							console.error 'Error while inserting:', err, (new Error).stack
							return

						console.log data

						data = ([].concat data)[0]

						console.log "Inserted reminder 'to #{data.task}'"

					@startReminder data
	
				catch e
					@reply origin, "Oh my, there was a problem! #{e.message}"
					console.error e.stack

		destroy: ->
			for reminder in @reminders
				reminder.cancel no
	
		startReminder: (data) ->
			delay = data.endTime - Date.now()

			reminder = {data}

			removeReminder = (removeFromDb = yes) =>
				console.log 'Removing reminder...'
				i = @reminders.indexOf reminder
				@reminders[i..i] = []

				if removeFromDb
					@db.remove {_id: data._id}, {}, (err, numRemoved) ->
						return console.error err.stack if err?

						console.log "Removed #{numRemoved} reminders from DB"

			cancelSchedule = @schedule delay, =>
				console.log data
				console.log "Reminder for #{data.target}: #{data.task}"
	
				bot = _.find @getBotManager().bots, (bot) => bot.getName() is data.botName
	
				text = "Hey #{data.target}! #{if data.own then 'You' else data.target} wanted me to remind you to '#{data.task}'!"
	
				bot.notice data.target, text
				bot.say data.target, text

				removeReminder()

			reminder.cancel = (removeFromDb) ->
				removeReminder removeFromDb
				cancelSchedule()

			@reminders.push reminder

		schedule: (delay, fn) ->
			maxDelay = 24 * (24*60*60*1000) # 24 days

			start = Date.now()
			timeoutId = null

			handle = ->
				timeoutId = setTimeout (->
					if start+delay <= Date.now() then fn()

					else handle()

				), (Math.min maxDelay, Math.max delay, 0)

			handle()

			(-> clearTimeout timeoutId) # cancel function

		stripPunctuation: (string) -> string.replace /[\.!?]+$/g, ''
	
	ReminderModule
