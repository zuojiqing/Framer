{_} = require "./Underscore"

{EventEmitter} = require "./EventEmitter"

LayerStatesIgnoredKeys = ["ignoreEvents"]

class exports.LayerStates extends EventEmitter
	
	constructor: (@layer) ->
		
		@_states = {}
		@_orderedStates = []
		
		@animationOptions =
			curve: "spring"
		
		# Always add the default state as the current
		@add "default", @layer.properties

		@_currentState = "default"
		@_previousStates = []
	
	add: (stateName, properties) ->
		# Add a state with a name and properties
		@_orderedStates.push stateName
		@_states[stateName] = properties

	remove: (stateName) ->
		
		if not @_states.hasOwnProperty stateName
			return
		
		delete @_states[stateName]
		@_orderedStates = _.without @_orderedStates, stateName
	
	switch: (stateName, animationOptions) ->
		
		# Switches to a specific state. If animationOptions are
		# given use those, otherwise the default options.
		
		if stateName is @_currentState
			return

		if not @_states.hasOwnProperty stateName
			throw Error "No such state: '#{stateName}'"
		
		@emit "willSwitch", @_currentState, stateName, @

		@_previousStates.push @_currentState
		@_currentState = stateName

		animationOptions ?= @animationOptions
		animationOptions.properties = {}
		
		animatingKeys = @animatingKeys()

		console.log animatingKeys

		for k, v of @_states[stateName]

			# Don't animate ignored properties
			if k in LayerStatesIgnoredKeys
				continue

			if k not in animatingKeys
				continue

			# Allow dynamic properties as functions
			v = v() if _.isFunction(v)
			
			animationOptions.properties[k] = v
			
		animation = @layer.animate animationOptions

		animation.on "stop", =>
			@emit "didSwitch", _.last @_previousStates, stateName, @
	
	switchInstant: (stateName) ->
		# Instantly switch to this new state
		@switch stateName,
			curve: "linear"
			time: 0

	states: ->
		# Return a list of all the possible states
		@_orderedStates

	animatingKeys: ->

		keys = []

		for stateName, state of @_states
			
			if stateName is "default"
				continue

			keys = _.union keys, _.keys state

		keys

	previous: (states, animationOptions) ->
		# Go to previous state in list
		states ?= @states()
		@switch Utils.arrayPrev(states, @_currentState), animationOptions

	next: (states, animationOptions) ->
		# Go to next state in list
		states ?= @states()
		@switch Utils.arrayNext(states, @_currentState), animationOptions


	last: (animationOptions) ->
		# Return to last state
		@switch _.last(@_previousStates), animationOptions
