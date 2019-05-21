extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var currently_gripping = false
var should_grip = false

# Which side of the entity is doing the gripping.
var grip_direction = Vector2(0, 0)

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
			print("RELEASE")
			if not grip_direction == Vector2(0, 0):
				calculate_grip_direction(Vector2(0, 0))
			gravity_enabled = true
			$MovementHandler.clear_overrides()
			print("aw shucks")
			
		
	if is_on_wall() or is_on_ceiling():
		if should_grip and not currently_gripping:
			print("HIT")
			motion.y = 0
			currently_gripping = true
			calculate_grip_direction(get_slide_collision(0).normal)
			gravity_enabled = false
			$MovementHandler.set_overrides({
				"down": funcref(self, "grip_move_down"),
				"idle": funcref(self, "grip_move_idle"),
				"left": funcref(self, "grip_move_left"),
				"right": funcref(self, "grip_move_right"),
				"up": funcref(self, "grip_move_up")
			})
		else:
			print("bummer")
	else:
		currently_gripping = false
		
		

func apply_motion():
	if not currently_gripping:
		.apply_motion()
	else:
#		motion.y = 0
		motion = move_and_slide(motion, UP)

func calculate_grip_direction(wall_normal):
	grip_direction -= wall_normal
#	breakpoint

func grip_move_down():
	print('grip down')
	motion.y = min(motion.y + ACCELERATION, MAX_SPEED)

func grip_move_idle():
	pass

func grip_move_left():
	print('grip left')
	if grip_direction.x + direction.x == 0:
		print("aw geez")
		return
	
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
#	dir_x = -1
	direction.x = -1
	playAnim('run', -1, 1.6)

func grip_move_right():
	print('grip right')
	if grip_direction.x + direction.x == 0:
		print("aw geez")
		return
	
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
#	dir_x = 1
	direction.x = 1
	playAnim('run', -1, 1.6)

func grip_move_up():
	print('grip up')
	motion.y = max(motion.y - ACCELERATION, -MAX_SPEED)

func get_height():
	return $CollisionShape2D.shape.height

func get_width():
	return $CollisionShape2D.shape.width