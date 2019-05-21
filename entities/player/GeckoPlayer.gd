extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var currently_gripping = false
var should_grip = false

func _ready():
	._ready()
	print("I'm a gecko.")