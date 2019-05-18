extends Node

var run_time = 0 setget ,get_run_time

func _process(delta):
	run_time += delta
	
func get_run_time():
	return run_time