extends Node

var current setget ,get_current_state
var last setget ,get_last_state

var current_state
var last_state
var first_time_in_state
var just_set_state
var current_state_time
var time = 0

func _process(delta):
	first_time_in_state = just_set_state
	time += 0 if first_time_in_state else delta
	just_set_state = false

func get_current_state():
	return current_state

func set_state(new_state):
	last_state = current_state
	current_state = new_state
	current_state_time = 0
	just_set_state = true
	first_time_in_state = true

func get_last_state():
	return last_state

func is_state(state):
	return current_state == state