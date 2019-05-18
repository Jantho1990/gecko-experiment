extends Node

###
# GUI CONFIGURABLE PROPERTIES
###

# The states associated with this machine.
export(Array, String) var states

# The default state.
export(String) var default

###
# PUBLICALLY ACCESSIBLE PROPERTIES
###

# Current state
var current = null setget _set_private

# Previous state
var previous = null setget _set_private

# Was state just set?
var just_set = false setget _set_private

# Amount of time spent in current state
var time = 0.00 setget _set_private

###
# PRIVATE PROPERTIES
###

# The state stack
var _stack = [] setget _set_private,_get_private

###
# METHODS
###

func _get_private():
	print("Not allowed to get private method.")

func _set_private(_throwaway_):
	print("Not allowed to set private method.")

func _ready():
	for state in states:
		if state == default:
			print(state)
			push(state)

func _process(delta):
	if just_set and time > 0:
		just_set = false
	
	time += delta

# Add a new state if it is not the current one.
func add(state):
	if _stack[0] == state:
		return
	
	push(state)

# Push a new state to the top of the stack.
func push(state):
	if states.find(state) == -1:
		print("State ", state, " not found in state machine ", self)
		return
	
	previous = _stack[0] if _stack.size() > 0 else null
	_stack.push_front(state)
	current = _stack[0]
	just_set = true
	time = 0
#	print(_stack)

# Remove the top state from the stack.
func pop():
	var removed_state = null
	if _stack.size() > 0:
		removed_state = _stack[0]
		_stack.pop_front()
		previous = removed_state
		time = 0
		if _stack.size() > 0:
			current = _stack[0]
		else:
			current = null
#		print(_stack)
	
	return removed_state

# Swap the current state with a new one.
func swap(state):
	if states.find(state) == -1:
		print("State ", state, " not found in state machine ", self)
		return
	
	if _stack[0] == state:
		return
	
	var ret = pop()
	push(state)
	
	return ret