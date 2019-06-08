extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var grip_pressed = false
var grip_releasing = false
var grip_hold = true
var gripping_surface = false



# Are we in a corner right now?
var in_corner = false
var corner_direction = Vector2(0, 0) # used to save the grip direction at the time a corner is being navigated

var movement_overrides setget _set_private,_get_private

onready var GripDetection = $GripDetection

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
	GripDetection.set_dimensions(get_width(), get_height())
	GripDetection.debug = true

func _physics_process(delta):
	update() # Used to trigger the _draw function
	
	if Input.is_action_pressed("ui_grip"):
		grip_pressed = true
		
	if Input.is_action_just_released("ui_grip"):
		grip_pressed = false
		grip_releasing = false
	
	if should_attempt_grip():
		GripDetection.scan_for_grippable_surfaces()
		if GripDetection.near_grippable_surface():
			grip_surface()
	elif should_release_grip():
		release_grip()
	elif grip_releasing:
		handle_release_cancel()
	
	if gripping_surface:
		handle_grip_movement()


###
# Other Methods
###

func should_attempt_grip():
	return grip_pressed and not gripping_surface and not grip_releasing

func should_release_grip():
	return (grip_releasing or Input.is_action_just_pressed("ui_grip")) and gripping_surface

func handle_release_cancel():
	GripDetection.scan_for_grippable_surfaces()
	if not GripDetection.near_grippable_surface():
		grip_releasing = false

func grip_surface():
	if not gripping_surface and GripDetection.grippable_surface_contact():
		gripping_surface = true
		gravity = false
		$MovementHandler.set_overrides(movement_overrides)
	else:
		motion += 500 * GripDetection.grip_direction

func release_grip():
	gripping_surface = false
	if in_corner:
		in_corner = false
	if not grip_releasing:
		grip_releasing = true
	gravity = true
	$MovementHandler.clear_overrides()

func handle_grip_movement():
	if Input.is_action_pressed("ui_down"):
		$MovementHandler.down()
	elif Input.is_action_pressed("ui_up"):
		$MovementHandler.up()
	else:
		$MovementHandler.idle()
	
	# Update gripping position
	GripDetection.scan_for_grippable_surfaces()
	if not GripDetection.near_grippable_surface():
		grip_releasing = true
	
	# Corner detection
	if GripDetection.in_obtuse_angle_corner():
		obtuse_angle_corner_transfer()
		print("obtuse")
	elif GripDetection.in_reflex_angle_corner():
		reflex_angle_corner_transfer()
		print("reflex")
	else:
#		print("nah")
		pass

func obtuse_angle_corner_transfer():
	if not in_corner:
		in_corner = true
		GripDetection.in_corner = true
		corner_direction = GripDetection.grip_direction
	rotation_degrees += 10 * (-corner_direction.x if corner_direction.x != 0 else -corner_direction.y)
	motion += 500 * corner_direction
	
	if GripDetection.grippable_surface_hit("left") and \
		GripDetection.grippable_surface_contact("left"):
#			breakpoint
			pass
	else:
		print("left ", GripDetection.grippable_surface["left"], position)
	if GripDetection.grippable_surface_hit("right") and \
		GripDetection.grippable_surface_contact("right"):
#			breakpoint
			pass
	elif GripDetection.grippable_surface_hit("right"):
		print("right ", GripDetection.grippable_surface["right"], position)
#	else:
#		print(grip_direction, position)
#		breakpoint

func reflex_angle_corner_transfer():
	pass

func grip_move_down():
	direction.y = 1
	if GripDetection.grip_direction.y + direction.y == 0:
		return
		
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
	if GripDetection.grip_direction.x + direction.x == 0:
		return
	
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
	
	playAnim('run', -1, 1.6)

func grip_move_right():
	direction.x = 1
	if GripDetection.grip_direction.x + direction.x == 0:
		return
	
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
	
	playAnim('run', -1, 1.6)

func grip_move_up():
	direction.y = -1
	if GripDetection.grip_direction.y + direction.y == 0:
		return
	
	motion.y = max(motion.y - ACCELERATION, -MAX_SPEED)

func get_height():
	return $CollisionShape2D.shape.extents.y * 2

func get_half_height():
	return $CollisionShape2D.shape.extents.y

func get_width():
	return $CollisionShape2D.shape.extents.x * 2

func get_half_width():
	return $CollisionShape2D.shape.extents.x