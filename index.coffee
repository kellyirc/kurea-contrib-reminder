module.exports = (Module) ->
	_ = require 'underscore'
	_.str = require 'underscore.string'

	{Lexer, Parser, ReminderParser} = require './parsing'
	
	tokens =
		space:
			matching: /\s+/g
			hidden: yes
	
		number:
			matching: /\d+(\.\d+)?/g
			value: (t) -> Number t.text
	
		word:
			matching: /\w+/g
	
	timeString = (time) ->
		timeParts =
			d: Math.floor(time / (24*60*60*1000))
			h: Math.floor(time / (60*60*1000)) % 24
			m: Math.floor(time / (60*1000)) % 60
			s: Math.floor(time / 1000) % 60
			ms: time % 1000
	
		units =
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
					l = new Lexer tokens
					p = new ReminderParser l, route.params.args
					data = p.parse()
	
					data.own = (data.target is 'me' or data.target is origin.user)
					data.target = origin.user if data.target is 'me'
	
					data.botName = origin.bot.getName()
	
					if data.time / (24*60*60*1000) > 24.8
						@reply origin, "Sorry, you can't set a with a duration greater than 24.8 days for now!"
						return
	
					@reply origin, "Alright, I'll remind #{if data.own then 'you' else data.target} to '#{data.task}' in #{timeString data.time}!"
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