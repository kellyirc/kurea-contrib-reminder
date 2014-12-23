module.exports = (Module) ->
	_ = require 'underscore'

	# {Lexer, Parser, ReminderParser} = require './parsing'
	parseReminder = require './parsing'
	formatTime = require './time-format'
	
	class ReminderModule extends Module
		shortName: "Reminder"
	
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
					data.endTime = Date.now() + data.time

					data.own = (data.target is 'me' or data.target is origin.user)
					data.target = origin.user if data.target is 'me'
	
					data.botName = origin.bot.getName()
	
					if data.time / (24*60*60*1000) > 24.8
						@reply origin, "Sorry, you can't set a with a duration greater than 24.8 days for now!"
						return
	
					@reply origin, "Alright, I'll remind #{if data.own then 'you' else data.target} to '#{data.task}' in #{formatTime data.time}!"
					console.log data
	
					@db.insert data, (err, data) =>
						if err?
							console.error 'Error while inserting:', err, (new Error).stack
							return

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
	
				bot.say data.target, text
				bot.notice data.target, text

				removeReminder()

			reminder.cancel = (removeFromDb) ->
				removeReminder removeFromDb
				cancelSchedule()

			@reminders.push reminder

		schedule: (delay, fn) ->
			delay = Math.max delay, 0

			timeoutId = setTimeout fn, delay

			(-> clearTimeout timeoutId) # cancel function

		stripPunctuation: (string) -> string.replace /[\.!?]+$/g, ''
	
	ReminderModule