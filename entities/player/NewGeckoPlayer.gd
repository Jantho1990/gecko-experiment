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
var grippable_surface = {} # Keeps track of which sides of entity face a grippable surface.

var grip_vectors = {}

# Which side of the entity is doing the gripping.
var grip_direction = Vector2(0, 0)

# Are we in a corner right now?
var in_corner = false
var corner_direction = Vector2(0, 0) # used to save the grip direction at the time a corner is being navigated

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
	update() # Used to trigger the _draw function
	
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
	if not gripping_surface and grippable_surface_contact():
		gripping_surface = true
		gravity = false
		$MovementHandler.set_overrides(movement_overrides)
	else:
		motion += 500 * grip_direction

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
	scan_for_grippable_surfaces()
	if not near_grippable_surface():
		grip_releasing = true
	
	# Corner detection
	if in_obtuse_angle_corner():
		obtuse_angle_corner_transfer()
		print("obtuse")
	elif in_reflex_angle_corner():
		reflex_angle_corner_transfer()
		print("reflex")
	else:
#		print("nah")
		pass
	
	# Corner detection
	# For obtuse-angle corners ( 90 < angle < 180):
	# - rotate away from current surface
	# - push entity up towards target surface
	# - this should reduce the distance of the mid-raycast for the gripping side
	# - when the gripping side raycast approaches or reaches zero
	#   - snap rotation to uniform angle
	#   - end push
	# For reflex-angle corners ( angle > 180deg):
	# - rotate towards current surface, which should also rotate towards target surface
	# - everything else is the same as for acute-angle corners
	# Threshold should prolly be < 0.01
	# - this would definitely require rotation snap

func in_obtuse_angle_corner():
	return in_corner or grippable_surface_hit(["up", "down"])

func obtuse_angle_corner_transfer():
	if not in_corner:
		in_corner = true
		corner_direction = grip_direction
	rotation_degrees += 0.1 * (-corner_direction.x if corner_direction.x != 0 else -corner_direction.y)
	motion += 500 * corner_direction
	
	if grippable_surface_hit("left") and \
		grippable_surface_contact("left"):
			breakpoint
	else:
		print("left ", grippable_surface["left"], position)
	if grippable_surface_hit("right") and \
		grippable_surface_contact("right"):
			breakpoint
	elif grippable_surface_hit("right"):
		print("right ", grippable_surface["right"], position)
#	else:
#		print(grip_direction, position)
#		breakpoint

func in_reflex_angle_corner():
	return not grippable_surface_hit(["left", "right"])

func reflex_angle_corner_transfer():
	pass

func grippable_surface_hit(direction = ""):
	if typeof(direction) == TYPE_STRING and direction == "":
		for surface in grippable_surface.values():
			if surface.hit:
				return true
	elif typeof(direction) == TYPE_ARRAY:
		for dir in direction:
			if grippable_surface.has(dir):
				if grippable_surface[dir].hit:
					return true
			else:
				print("Unknown grip direction: ", dir)
	elif grippable_surface.has(direction):
		if grippable_surface[direction].hit:
			return true
	else:
		print("Unknown grip direction: ", direction)
	
	return false

func grippable_surface_hit_all(direction = ""):
	if typeof(direction) == TYPE_STRING and direction == "":
		return grippable_surface_hit(direction)
	elif typeof(direction) == TYPE_ARRAY:
		for dir in direction:
			var ret = grippable_surface_hit(dir)
			if not ret:
				return false
		return true

func grippable_surface_contact(direction = ""):
	if direction == "":
		for surface in grippable_surface.values():
			if surface.hit:
				return true
	
	if grippable_surface.has(direction):
		if grippable_surface[direction].contact:
			return true
	else:
		print("Unknown grip direction: ", direction)
	
	return false

func in_contact_range(distance):
	var threshold = 0.015
	return distance <= threshold

func surface_in_contact_range(direction = null):
	if direction == null:
		return in_contact_range(direction.distance)
	else:
		for surface in grippable_surface.values():
			if in_contact_range(surface.distance):
				return true
	
	return false

func scan_for_grippable_surfaces():
	calculate_grippable_surfaces()
	calculate_grip_direction()

func near_grippable_surface():
	for surface in grippable_surface.values():
		if surface.hit:
			return true
	return false

func calculate_grip_direction():
	grip_direction = Vector2(0, 0)
	for key in grippable_surface:
		var surface = grippable_surface[key]
		if surface.hit:
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
		"right": Vector2(get_half_width(), 0), # Right
		"left": Vector2(-get_half_width(), 0), # Left
		"down": Vector2(0, get_half_height()), # Down
		"up": Vector2(0, -get_half_height()), # Up
		"down-right": Vector2(get_half_width(), get_half_height()), # Down-Right
		"down-left": Vector2(-get_half_width(), get_half_height()), # Down-Left
		"up-right": Vector2(get_half_width(), -get_half_height()), # Up-Right
		"up-left": Vector2(-get_half_width(), -get_half_height()) # Up-Left
	}
	
	# The world around the entity.
	var space_state = get_world_2d().direct_space_state
	
	var ret = {}
	for key in grip_vectors:
		var grip_vector = grip_vectors[key]
		var range_value = grip_range * grip_vector.normalized()
		var result = space_state.intersect_ray(
			position + grip_vector,
			position + grip_vector + range_value,
			[self]
		)
		var hit = !result.empty()
		ret[key] = { "hit": hit, "grip_vector": grip_vector, "contact": false }
		if hit:
			var distance = result.position.distance_to(position + grip_vector)
			ret[key] = {
				"hit": hit,
				"distance": distance,
				"contact": in_contact_range(distance),
				"raycast": result,
				"grip_vector": grip_vector
			}
	
	grippable_surface = ret

# debug only
func _draw():
	if not grip_vectors.empty():
		for surface in grippable_surface.values():
			var grip_vector = surface.grip_vector
			var range_value = grip_range * grip_vector.normalized()
#			if grip_pressed:
#				print("Position: ", position, ", Global Position: ", global_position, ", Grip Vector: ", grip_vector)
#			draw_circle(Vector2(0, 0), 50, Color(1, 1, 1))
			var color = Color(1, 0, 0)
			if surface.contact:
				color = Color(0, 1, 0)
			elif surface.hit:
				color = Color(0, 0, 1)
			draw_line(Vector2(0, 0) + grip_vector, grip_vector + range_value, color, 1)

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