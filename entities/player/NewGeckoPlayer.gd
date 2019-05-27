extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var currently_gripping = false
var should_grip = false

# If true, entity is transferring from wall to ceiling,
# or vice versa.
var grip_transfer_in_progress = false
var in_corner = false
var grip_transfer_rotation_angle = 0

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
	print(motion.y)
	should_grip = false
	if Input.is_action_pressed("ui_grip"):
		if not currently_gripping:
			should_grip = true
		else:
			currently_gripping = false
			grip_direction = Vector2(0, 0)
			gravity = true
			$MovementHandler.clear_overrides()
	
	if grip_transfer_in_progress:
#		rotate_to_ceiling()
		pass
	
	if is_on_wall() and is_on_ceiling():
		if not in_corner:
			grip_transfer_in_progress = true
			in_corner = true
		else:
			print("Still in corner.")
	elif is_on_wall() or is_on_ceiling():
		in_corner = false
		if should_grip and not currently_gripping:
			motion.y = 0
			currently_gripping = true
			calculate_grip_direction(get_slide_collision(0).normal)
			gravity = false
			$MovementHandler.set_overrides(movement_overrides)
	else:
		in_corner = false
		currently_gripping = false
	
	if currently_gripping:
		print("gripping...", grip_direction)
		if Input.is_action_pressed("ui_down"):
			$MovementHandler.down()
		elif Input.is_action_pressed("ui_up"):
			$MovementHandler.up()
		else:
			$MovementHandler.idle()
	
	if not currently_gripping:
		if grip_direction != Vector2(0, 0):
			grip_direction = Vector2(0, 0)
		gravity = true
		$MovementHandler.clear_overrides()

func apply_motion():
	if not currently_gripping:
		.apply_motion()
	else:
		# apply a smidgen of force to trigger is_on_whatever calculations
		motion += 527.015 * grip_direction # I have no idea why 7.015 is the minimum needed force for this to work, I just trial-and-error'd it.
		print("premotion", motion, grip_direction)
		motion = move_and_slide(motion, UP)
		print(motion, grip_direction)

func calculate_grip_direction(wall_normal): # Translate the wall_normal into grip direction, which matches our regular direction's convention.
	grip_direction -= wall_normal

func grip_move_down():
	direction.y = 1
	motion.y = min(motion.y + ACCELERATION, MAX_SPEED)

func grip_move_idle():
	friction = true
	if motion.y > 0:
		motion.y = max(motion.y - ACCELERATION, 0)
	elif motion.y < 0:
		motion.y = min(motion.y + ACCELERATION, 0)
	
	# We already have horizontal friction handling in base move_idle,
	# so let's steal it.
	.move_idle()

func grip_move_left():
	direction.x = -1
	if grip_direction.x + direction.x == 0:
		return
	
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
	
	playAnim('run', -1, 1.6)

func grip_move_right():
	direction.x = 1
	if grip_direction.x + direction.x == 0:
		return
	
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
	
	playAnim('run', -1, 1.6)

func grip_move_up():
	direction.y = -1
	if grip_direction.y + direction.y == 0:
		return
	
	motion.y = max(motion.y - ACCELERATION, -MAX_SPEED)

func get_height():
	return $CollisionShape2D.shape.height

func get_width():
	return $CollisionShape2D.shape.width

func in_midair(delta):
	.in_midair(delta)
	if not in_corner and abs(rotation_degrees) > 0:
		rotation_degrees += sign(rotation_degrees) * lerp(rotation_degrees, 0, 0.5)

func rotate_to_ceiling():
	currently_gripping = true # Force this to stay true, since the rotation will throw it off.
	var dir = direction.x
	grip_transfer_rotation_angle += 5 * -dir
	rotation_degrees = grip_transfer_rotation_angle
	motion.y -= 500
	print("Rotation: ", grip_transfer_rotation_angle, " ", dir)
	if abs(grip_transfer_rotation_angle) >= 90:
		print("sHOT")
		grip_transfer_in_progress = false
		grip_transfer_rotation_angle = 0
		if not is_on_ceiling():
			position.y -= 500