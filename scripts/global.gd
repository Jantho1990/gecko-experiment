extends Node

var run_time = 0 setget ,get_run_time

func _process(delta):
	run_time += delta
	
func get_run_time():
	return run_time

func no_action_pressed():
	var actions = InputMap.get_actions()
	
	for action in actions:
		if Input.is_action_pressed(action):
			return false
	
	return true