extends KinematicBody2D

const UP = CONSTANTS.UP
const GRAVITY = CONSTANTS.GRAVITY * -UP.y
const ACCELERATION = 50
const MAX_SPEED = 200
const JUMP_HEIGHT = -550
const JUMP_FORGIVENESS = 0.08
const HEALTH_MAX = 10
const HEALTH_START = HEALTH_MAX

# Flags
export(bool) var dead = false # Is player dead?
export(bool) var flying = false # Is player flying?
export(bool) var gravity = true # Is gravity acting on player?
export(bool) var controllable = true # Can the player control the entity?
export(bool) var jumping = false # Is the player currently jumping?
export(bool) var falling = false # Is the player currently falling?

# Jump logic
var jump_forgiveness_time = 0
var current_jump_height = 0
#var jump_scale_time = 0

var direction = Vector2(1, 0)

#warning-ignore:unused_class_variable
var width setget ,get_width
#warning-ignore:unused_class_variable
var height setget ,get_height

var motion = Vector2()

# Hold timer when character is not allowed to move.
var immobile_timer

var friction = false

onready var health = $Health

func _ready():
	$MovementHandler.set_defaults({
		"down": funcref(self, "move_down"),
		"idle": funcref(self, "move_idle"),
		"left": funcref(self, "move_left"),
		"right": funcref(self, "move_right"),
		"up": funcref(self, "move_up")
	})
	
	EventBus.listen("WorldMap_loaded", self, "on_WorldMap_loaded")
	
	EventBus.dispatch(name + "_loaded", {
		"node": self
	})

func _input(event):
	pass

func _physics_process(delta):
	if $Health.current == 0:
		die()
	
	if dead:
		in_death()
		return
	
	apply_gravity()
	
	friction = false
	
	# Left/Right Movement
	if Input.is_action_pressed('ui_right'):
		$MovementHandler.right()
	elif Input.is_action_pressed('ui_left'):
		$MovementHandler.left()
	elif global.no_action_pressed():
		$MovementHandler.idle()
	
	# Jump/Fall
	if is_on_floor():
		on_floor()
	elif flying:
		in_flight()
	else:
		in_midair(delta)
	
	apply_motion()


###
# Property setters/getters
###
func get_height():
	return $CollisionShape2D.shape.height

func get_width():
	return $CollisionShape2D.shape.radius * 2


###
# Movement
###
func move_down():
	print("down")
	pass

func move_idle():
	friction = true
	motion.x = lerp(motion.x, 0, 0.2)
	playAnim('idle')

func move_left():
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
	$Sprite.flip_h = true
	direction.x = -1
	playAnim('run', -1, 1.6)

func move_right():
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
	$Sprite.flip_h = false
	direction.x = 1
	playAnim('run', -1, 1.6)

func move_up():
#	motion.y = JUMP_HEIGHT
	jump()


###
# Other methods
###

# Apply the force of gravity.
func apply_gravity():
	if gravity and not flying:
		motion.y += GRAVITY

# Final movement integration
func apply_motion():
	motion = move_and_slide(motion, UP, true) # true should be stopping the slide, but it isn't for some reason, debug this later	

# Kill the player.
func die():
	if not dead:
		dead = true
#		$Sounds/Scream.play()
		print("dead")
		playAnim("die")
		# Disable child processes so nothing updates further
		for child in get_children():
			if child.name != "Sounds":
				print(child.name)
				child.set_physics_process(false)
				child.set_process(false)

# Stuff to do after the player has died.
func in_death():
	# We still want to allow gravity so the player doesn't hang in mid-air while they die
	apply_gravity()
	if is_on_floor():
		motion.x = 0
	motion = move_and_slide(motion, UP)

# Stuff to do while player is flying.
func in_flight():
	playAnim('flying')
	if Input.is_action_pressed("ui_up"):
		$MovementHandler.up()
	elif Input.is_action_pressed("ui_down"):
		$MovementHandler.down()
	else:
		$MovementHandler.idle()

# Stuff to do while player is in midair, but not flying.
func in_midair(delta):
	if jumping and \
		current_jump_height != JUMP_HEIGHT and \
		Input.is_action_pressed('ui_up'):
			$MovementHandler.up()
	
	if motion.y < 0:
		playAnim('jump')
	else:
		playAnim('fall')
		falling = true
		jump_forgiveness(delta)
	
	if friction == true:
		motion.x = lerp(motion.x, 0, 0.05)

# Stuff to do when a damaging force hits the player.
func hit(damage, source = null):
	print("HIT DAMAGE:", damage, " FROM ", source)
	$MovementHandler.freeze()
	immobile_timer = Timer.new()
	immobile_timer.start(0.5)
	immobile_timer.connect("timeout", self, "_on_Immobile_timer_end")
	motion.y = -200
	motion.x = 400 * sign(source.direction.x if source != null else 0)
	$SanitySplatter.emitting = true
	motion = move_and_slide(motion, UP)
	add_child(immobile_timer)
	print("freeze")

# Make the player jump.
func jump():
	if not jumping:
		jumping = true
	if current_jump_height > JUMP_HEIGHT and motion.y != JUMP_HEIGHT:
		current_jump_height += (JUMP_HEIGHT / 10.00)
	else:
		current_jump_height = JUMP_HEIGHT
		jumping = false
	motion.y = current_jump_height
#	print("jumping", current_jump_height)

func jump_forgiveness(delta):
	if jump_forgiveness_time <= 0:
		jump_forgiveness_time = JUMP_FORGIVENESS
	else:
		jump_forgiveness_time -= delta
		if jump_forgiveness_time <= 0:
			falling = true
			jumping = false

func _on_Immobile_timer_end():
	print("unfreeze")
	$MovementHandler.unfreeze()
	$SanitySplatter.emitting = false
	remove_child(immobile_timer)

func on_floor():
	if falling:
		falling = false
	
	if Input.is_action_just_pressed('ui_up'):
#		$Sounds/Jump.play()
		$MovementHandler.up()
	else:
		current_jump_height = 0
	
	if friction:
		motion.x = lerp(motion.x, 0, 0.2)

func playAnim(anim, custom_blend = -1, custom_speed = 1.0):
	if $Sprite/AnimationPlayer.current_animation != anim || !$Sprite/AnimationPlayer.is_playing():
		$Sprite/AnimationPlayer.play(anim, custom_blend, custom_speed)

func set_health(amount):
	health.set_health(amount)

func spawn_acceptable(tilemap, pos):
	var cell = tilemap.world_to_map(pos)
	var above = tilemap.tile_above_pos(pos)
	var below = tilemap.tile_below_pos(pos)
	
	var map = tilemap.get_parent()
	for child in map.get_children():
		if child.get("position") != null:
			if pos == child.position:
				return false
	
	if tilemap.get_cell(above.x, above.y) == -1 \
		and tilemap.get_cell(cell.x, cell.y) == -1 \
		and tilemap.get_cell(below.x, below.y) != -1:
			return true
	return false