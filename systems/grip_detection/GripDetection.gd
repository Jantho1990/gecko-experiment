extends Node2D

const THRESHOLD = 1

# Toggle debugging on and off.
var debug = false

# Which side of the entity is doing the gripping.
var grip_direction = Vector2(0, 0)

var grip_vectors = {}
var grippable_surface = {}
var grip_range = 21

var in_corner = false

var width = 1 # start at 1 to prevent division by 0
var height = 1 # start at 1 to prevent division by 0

var raycasts = {}

# Bitmask values for surface hit directions
const direction_names_bitmask = {
	"right": 1,
	"left": 2,
	"down": 4,
	"up": 8,
	"down-right": 16,
	"down-left": 32,
	"up-right": 64,
	"up-left": 128
}

func _ready():
	pass
#	grip_vectors = create_grip_vectors()
#	raycasts = create_raycasts()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		breakpoint
	calculate_grippable_surfaces()
	
	# Only draw if holding down the key
	if debug:
		update()

func _draw():
	if debug:
		draw_grip_range()

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
	var ret = {}
	for key in grip_vectors:
		var grip_vector = grip_vectors[key]
		var range_value = grip_range * grip_vector.normalized()
		var raycast = raycasts[key]
		var result = get_raycast_result(raycast)
		var hit = !result.empty()
		ret[key] = {
			"hit": hit,
			"grip_vector": grip_vector,
			"contact": false,
			"raycast": raycast
		}
		if hit:
#			var distance = result.position.distance_to(raycast.global_position) # need global_position because position just returns this node, which is relative to its parent
#			breakpoint
			ret[key] = {
				"hit": hit,
				"distance": result.distance,
				"contact": in_contact_range(result.distance),
				"result": result,
				"raycast": raycast,
				"grip_vector": grip_vector
			}
	
	grippable_surface = ret

func create_grip_vectors():
	# An array of vectors representing the eight sides
	# of the entity, which will be used to perform
	# eight raycasts.
	# Adding half-dimensions accounts for the dimensions
	# of the entity so grip detection doesn't start from
	# the dead center of entity.
	return {
		"right": Vector2(get_half_width(), 0), # Right
		"left": Vector2(-get_half_width(), 0), # Left
		"down": Vector2(0, get_half_height()), # Down
		"up": Vector2(0, -get_half_height()), # Up
		"down-right": Vector2(get_half_width(), get_half_height()), # Down-Right
		"down-left": Vector2(-get_half_width(), get_half_height()), # Down-Left
		"up-right": Vector2(get_half_width(), -get_half_height()), # Up-Right
		"up-left": Vector2(-get_half_width(), -get_half_height()) # Up-Left
	}

func create_raycast(grip_vector, range_value):
	var ray = RayCast2D.new()
	ray.position += grip_vector
	ray.cast_to = range_value
	ray.exclude_parent = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.enabled = true
	ray.add_exception(get_parent())
	return ray

func create_raycasts():
	var ret = {}
	for key in grip_vectors:
		var grip_vector = grip_vectors[key]
		var range_value = grip_range * grip_vector.normalized()
		var raycast = create_raycast(grip_vector, range_value)
		add_child(raycast)
		ret[key] = raycast
	return ret

func draw_grip_range():
	if not grip_vectors.empty():
		for surface in grippable_surface.values():
			var grip_vector = surface.grip_vector
			var range_value = grip_range * grip_vector.normalized()
			var raycast = surface.raycast
#			if grip_pressed:
#				print("Position: ", position, ", Global Position: ", global_position, ", Grip Vector: ", grip_vector)
#			draw_circle(Vector2(0, 0), 50, Color(1, 1, 1))
			var color = Color(1, 0, 0)
			if surface.contact:
				color = Color(0, 1, 0)
			elif surface.hit:
				color = Color(0, 0, 1)
			draw_line(raycast.position, raycast.position + raycast.cast_to, color)
			var ln = raycast.position + raycast.cast_to
#			draw_line(Vector2(0, 0) + grip_vector, grip_vector + range_value, color, 1)

# Identify what kind of corner we are in.
func detect_corner_type():
	# Need to have various configurations of
	# surface detections which indicate what
	# kind of corner we are hitting.
	#var hits_and_contacts = get_surface_hits() + (get_surface_contacts() * 2) # multiplying contacts to distinguish their bitmasks from the hits
	var contacts_and_hits = get_surface_contacts_and_hits()
#	print(contacts_and_hits)
	match contacts_and_hits:
		["left", "up", _, "up-right", "up-left", ..]:
			return "up left 90"
		["right", "up", _, "up-right", "up-left", ..]:
			return "up right 90"
		["left", "down", "down-right", "down-left", ..]:
			return "down left 90"
		["right", "down", "down-right", "down-left", ..]:
			return "down right 90"
		_:
			return ""

func get_height():
	return height

func get_half_height():
	return height / 2

func get_width():
	return width

func get_half_width():
	return width / 2

# Return a bitmask number of all contacted surfaces
func get_surface_contacts():
	var ret = 0
	for key in grippable_surface:
		var surface = grippable_surface[key]
		if surface.contact:
			ret += direction_names_bitmask[key]
	return ret

func get_surface_contacts_and_hits():
	var ret = []
	for key in grippable_surface:
		var surface = grippable_surface[key]
		if surface.contact or surface.hit:
			ret.push_back(key)
	return ret

# Return a bitmask number of all hit surfaces
func get_surface_hits():
	var ret = 0
	for key in grippable_surface:
		var surface = grippable_surface[key]
		if surface.hit:
			ret += direction_names_bitmask[key]
	return ret

func get_raycast_result(raycast):
	raycast.force_raycast_update() # this is needed because the parent has moved since the last calculation, which throws off the distance calculation; feels ugly but the alternative is copying parent motion into the distance calculation, which seems worse
	if raycast.is_colliding():
		var distance = raycast.get_collision_point().distance_to(raycast.global_position)
		return {
			"position": raycast.get_collision_point(),
			"collider": raycast.get_collider(),
			"distance": distance
		}
	return {}

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

func in_contact_range(distance):
	return distance <= THRESHOLD

func in_corner():
	return detect_corner_type() != ""

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
#	return in_corner or grippable_surface_hit(["up", "down"])
	return in_corner or \
		grippable_surface_hit_all(["up-left", "up-right", "left", "up"]) or \
		grippable_surface_hit_all(["down-left", "down-right", "left", "down"])

func in_reflex_angle_corner():
	return not grippable_surface_hit(["left", "right", "up", "down"])

func near_grippable_surface():
	for surface in grippable_surface.values():
		if surface.hit:
			return true
	return false

func scan_for_grippable_surfaces():
	calculate_grippable_surfaces()
	calculate_grip_direction()

func set_dimensions(width, height):
	self.width = width
	self.height = height
	grip_vectors = create_grip_vectors()
	raycasts = create_raycasts()

func surface_in_contact_range(direction = null):
	if direction == null:
		return in_contact_range(direction.distance)
	else:
		for surface in grippable_surface.values():
			if in_contact_range(surface.distance):
				return true
	
	return false