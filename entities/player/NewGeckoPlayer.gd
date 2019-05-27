extends "res://entities/player/Player.gd"

###
# Controls whether the player is currently gripping a wall or ceiling
# and if they should be doing that.
###
var grip_pressed = false
var grip_active = false
var gripping_surface = false
var grip_range = 55 # How close entity needs to be in order to initiate grip, in pixels.

var grip_vectors = null

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
		var near_grippable_surface = scan_for_grippable_surface()
	else:
		grip_pressed = false
	update()
	


###
# Other Methods
###

func scan_for_grippable_surface():
	var grips = calculate_grip_vectors(position)
	print(grips)

func calculate_grip_vectors(pos):
	# An array of vectors representing the eight sides
	# of the entity, which will be used to perform
	# eight raycasts.
	grip_vectors = [
		Vector2(grip_range, 0),
		Vector2(-grip_range, 0),
		Vector2(0, grip_range),
		Vector2(0, -grip_range),
		Vector2(grip_range, grip_range).normalized() * grip_range,
		Vector2(-grip_range, grip_range).normalized() * grip_range,
		Vector2(grip_range, -grip_range).normalized() * grip_range,
		Vector2(-grip_range, -grip_range).normalized() * grip_range
	]
	
	# The world around the entity.
	var space_state = get_world_2d().direct_space_state
	
	var ret = []
	for grip_vector in grip_vectors:
		var result = space_state.intersect_ray(global_position, grip_vector, [self])
		ret.push_back(result)
	
	return ret

# debug only
func _draw():
	if grip_vectors != null:
		for grip_vector in grip_vectors:
			if grip_pressed:
				print("Position: ", position, ", Global Position: ", global_position, ", Grip Vector: ", grip_vector)
#			draw_circle(Vector2(0, 0), 50, Color(1, 1, 1))
			draw_line(Vector2(0, 0), grip_vector, Color(1, 0, 0), 1)

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