extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var currently_gripping = false
var should_grip = false

# Which side of the entity is doing the gripping.
var grip_direction = Vector2(0, 0)

var movement_overrides setget _set_private,_get_private 

func _set_private(_throwaway_):
	print("Setting not allowed.")

func _get_private():
	print("Getting not allowed.")

func _ready():
	movement_overrides = {
		"down": funcref(self, "grip_move_down"),
		"idle": funcref(self, "grip_move_idle"),
		"left": funcref(self, "grip_move_left"),
		"right": funcref(self, "grip_move_right"),
		"up": funcref(self, "grip_move_up")
	}

func _physics_process(delta):
	should_grip = false
	if Input.is_action_just_pressed("ui_grip"):
		if not currently_gripping:
			should_grip = true
		else:
			currently_gripping = false
			grip_direction = Vector2(0, 0)
			gravity_enabled = true
			$MovementHandler.clear_overrides()
			
		
	if is_on_wall() or is_on_ceiling():
		if should_grip and not currently_gripping:
			motion.y = 0
			currently_gripping = true
			calculate_grip_direction(get_slide_collision(0).normal)
			gravity_enabled = false
			$MovementHandler.set_overrides(movement_overrides)
	else:
		currently_gripping = false
	
	if currently_gripping:
		if Input.is_action_pressed("ui_down"):
			$MovementHandler.down()
		elif Input.is_action_pressed("ui_up"):
			$MovementHandler.up()
		else:
			$MovementHandler.idle()
	
	if not currently_gripping:
		if grip_direction != Vector2(0, 0):
			grip_direction = Vector2(0, 0)
		gravity_enabled = true
		$MovementHandler.clear_overrides()

func apply_motion():
	if not currently_gripping:
		.apply_motion()
	else:
#		motion.y = 0
		# apply a smidgen of force to trigger is_on_whatever calculations
		motion += 7.015 * grip_direction # I have no idea why 7.015 is the minimum needed force for this to work, I just trial-and-error'd it.
		motion = move_and_slide(motion, UP)

func calculate_grip_direction(wall_normal): # Translate the wall_normal into grip direction, which matches our regular direction's convention.
	grip_direction -= wall_normal

func grip_move_down():
	direction.y = 1
	motion.y = min(motion.y + ACCELERATION, MAX_SPEED)

func grip_move_idle():
	if motion.y > 0:
		motion.y = max(motion.y - ACCELERATION, 0)
	elif motion.y < 0:
		motion.y = min(motion.y + ACCELERATION, 0)

func grip_move_left():
	direction.x = -1
	if grip_direction.x + direction.x == 0:
		return
	
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
#	dir_x = -1
	playAnim('run', -1, 1.6)

func grip_move_right():
	direction.x = 1
	if grip_direction.x + direction.x == 0:
		return
	
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
#	dir_x = 1
	playAnim('run', -1, 1.6)

func grip_move_up():
	direction.y = -1
	motion.y = max(motion.y - ACCELERATION, -MAX_SPEED)

func get_height():
	return $CollisionShape2D.shape.height

func get_width():
	return $CollisionShape2D.shape.width