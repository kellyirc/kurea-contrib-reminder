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
	
			# @db.find {}, (err, docs) =>
			# 	@startReminder doc for doc in docs
	
			@addRoute 'remind :args', (origin, route) =>
				try
					data = parseReminder route.params.args

					data.own = (data.target is 'me' or data.target is origin.user)
					data.target = origin.user if data.target is 'me'
	
					data.botName = origin.bot.getName()
	
					if data.time / (24*60*60*1000) > 24.8
						@reply origin, "Sorry, you can't set a with a duration greater than 24.8 days for now!"
						return
	
					@reply origin, "Alright, I'll remind #{if data.own then 'you' else data.target} to '#{data.task}' in #{formatTime data.time}!"
					console.log data
	
					# @db.insert data, (err) => console.log "Insertion: ", if err? then "ERROR: #{err}" else "OK"
					@startReminder data
	
				catch e
					@reply origin, "Oh my, there was a problem! #{e.message}"
					console.error e.stack
	
		startReminder: (data) ->
			# setTimeout to handle reminder schtuff
			@reminders.push data

			data.timeoutId = setTimeout =>
				console.log "Reminder for #{data.target}: #{data.task}"
	
				bot = _.find @getBotManager().bots, (bot) => bot.getName() is data.botName
	
				text = "Hey #{data.target}! #{if data.own then 'You' else data.target} wanted me to remind you to '#{data.task}'!"
	
				bot.say data.target, text
				bot.notice data.target, text
			, data.time
	
	
	ReminderModule