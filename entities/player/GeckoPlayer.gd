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

func _physics_process(delta):
	should_grip = false
	if Input.is_action_just_pressed("ui_grip"):
		if not currently_gripping:
			print("Grip!")
			should_grip = true
		else:
			currently_gripping = false
		
	if is_on_wall() or is_on_ceiling():
		if should_grip:
			print("HIT")
			currently_gripping = true
	else:
		currently_gripping = false

func apply_motion():
	if not currently_gripping:
		.apply_motion()
	else:
		motion.y = 0
		motion = move_and_slide(motion, UP)