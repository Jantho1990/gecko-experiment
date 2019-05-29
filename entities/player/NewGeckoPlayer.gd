extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var grip_pressed = false
var grip_releasing = false
var grip_hold = true
var gripping_surface = false
var grip_range = 15 # How close entity needs to be in order to initiate grip, in pixels.
var grippable_surface = [] # Keeps track of which sides of entity face a grippable surface.

var grip_vectors = {}

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
	if Input.is_action_pressed("ui_grip"):
		grip_pressed = true
		
	if Input.is_action_just_released("ui_grip"):
		grip_pressed = false
		grip_releasing = false
	
	if should_attempt_grip():
		scan_for_grippable_surfaces()
		if near_grippable_surface():
			grip_surface()
	elif should_release_grip():
		release_grip()
	elif grip_releasing:
		handle_release_cancel()
	
	if gripping_surface:
		handle_grip_movement()
	
	update()


###
# Other Methods
###

func should_attempt_grip():
	return grip_pressed and not gripping_surface and not grip_releasing

func should_release_grip():
	return (grip_releasing or Input.is_action_just_pressed("ui_grip")) and gripping_surface

func handle_release_cancel():
	scan_for_grippable_surfaces()
	if not near_grippable_surface():
		grip_releasing = false

func grip_surface():
	motion += 500 * grip_direction
	gravity = false
	$MovementHandler.set_overrides(movement_overrides)
	# cheating for now because we technically should wait until contact with the surface,
	# but I'm not ready to write the code calculating when we actually hit the surface
	gripping_surface = true

func release_grip():
	gripping_surface = false
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
	scan_for_grippable_surfaces()
	if not near_grippable_surface():
		grip_releasing = true

func scan_for_grippable_surfaces():
	calculate_grippable_surfaces()
	calculate_grip_direction()

func near_grippable_surface():
	for surface in grippable_surface.values():
		if surface:
			return true
	return false

func calculate_grip_direction():
	grip_direction = Vector2(0, 0)
	for key in grippable_surface:
		var surface = grippable_surface[key]
		if surface:
			match key:
				"right":
					grip_direction += Vector2(1, 0)
				"left":
					grip_direction += Vector2(-1, 0)
				"down":
					grip_direction += Vector2(0, 1)
				"up":
					grip_direction += Vector2(0, -1)

func calculate_grippable_surfaces(pos = position):
	# An array of vectors representing the eight sides
	# of the entity, which will be used to perform
	# eight raycasts.
	# Adding half-dimensions accounts for the dimensions
	# of the entity so grip detection doesn't start from
	# the dead center of entity.
	grip_vectors = {
		"right": Vector2(grip_range + get_half_width(), 0), # Right
		"left": Vector2(-grip_range - get_half_width(), 0), # Left
		"down": Vector2(0, grip_range + get_half_height()), # Down
		"up": Vector2(0, -grip_range - get_half_height()), # Up
		"down-right": Vector2(grip_range, grip_range).normalized() * grip_range + Vector2(get_half_width(), get_half_height()), # Down-Right
		"down-left": Vector2(-grip_range, grip_range).normalized() * grip_range + Vector2(-get_half_width(), get_half_height()), # Down-Left
		"up-right": Vector2(grip_range, -grip_range).normalized() * grip_range + Vector2(get_half_width(), -get_half_height()), # Up-Right
		"up-left": Vector2(-grip_range, -grip_range).normalized() * grip_range + Vector2(-get_half_width(), -get_half_height()) # Up-Left
	}
	
	# The world around the entity.
	var space_state = get_world_2d().direct_space_state
	
	var ret = {}
	for key in grip_vectors:
		var grip_vector = grip_vectors[key]
		var result = space_state.intersect_ray(position, position + grip_vector, [self])
		var hit = !result.empty()
		ret[key] = (hit)
	
	grippable_surface = ret

# debug only
func _draw():
	if not grip_vectors.empty():
		for grip_vector in grip_vectors.values():
#			if grip_pressed:
#				print("Position: ", position, ", Global Position: ", global_position, ", Grip Vector: ", grip_vector)
#			draw_circle(Vector2(0, 0), 50, Color(1, 1, 1))
			draw_line(Vector2(0, 0), grip_vector, Color(1, 0, 0), 1)

func grip_move_down():
	direction.y = 1
	if grip_direction.y + direction.y == 0:
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
	return $CollisionShape2D.shape.extents.y * 2

func get_half_height():
	return $CollisionShape2D.shape.extents.y

func get_width():
	return $CollisionShape2D.shape.extents.x * 2

func get_half_width():
	return $CollisionShape2D.shape.extents.x