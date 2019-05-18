extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAVITY = 20
const ACCELERATION = 50
const MAX_SPEED = 200
const JUMP_HEIGHT = -550
const JUMP_FORGIVENESS = 0.08
const HEALTH_MAX = 10
const HEALTH_START = HEALTH_MAX

# Should this be an export?
var is_flying = false
var is_dead = false

# Jump logic
var jump_forgiveness_time = 0
var is_falling = false
var current_jump_height = 0
var is_jumping = false
var jump_scale_time = 0

var dir_x = 1 setget ,get_dir_x
var direction = Vector2(1, 0)
var width setget ,width
var height setget ,height

var motion = Vector2()
var motionHandler = {
	"down": "moveDown",
	"left": "moveLeft",
	"right": "moveRight",
	"up": "moveUp"
}

# Hold timer when character is not allowed to move.
var immobile_timer

onready var health = $Health
onready var spellCaster = $SanityCaster

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

func _physics_process(delta):
#	$SanityCaster.mana_current = $Health.current	
	if $Health.current == 0:
		die()
	
	if is_dead:
		# We still want to allow gravity so the player doesn't hang in mid-air while they die
		motion.y += GRAVITY
		if is_on_floor():
			motion.x = 0
		motion = move_and_slide(motion, UP)
		return
	
	if !is_flying:
		motion.y += GRAVITY
	
	var friction = false
	
	# Left/Right Movement
	if Input.is_action_pressed('ui_right'):
		$MovementHandler.right()
	elif Input.is_action_pressed('ui_left'):
		$MovementHandler.left()
	else:
		friction = true
		motion.x = lerp(motion.x, 0, 0.2)
		playAnim('idle')
	
	# Jump/Fall
	if is_on_floor():
		if Input.is_action_just_pressed('ui_up'):
#			$Sounds/Jump.play()
			$MovementHandler.up()
		else:
			current_jump_height = 0
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.2)
	elif is_flying:
		playAnim('flying')
		if Input.is_action_pressed("ui_up"):
			$MovementHandler.up()
		elif Input.is_action_pressed("ui_down"):
			$MovementHandler.down()
		else:
			$MovementHandler.idle()
	else:
		if is_jumping and \
			current_jump_height != JUMP_HEIGHT and \
			Input.is_action_pressed('ui_up'):
				$MovementHandler.up()
		
		if motion.y < 0:
			playAnim('jump')
		else:
			playAnim('fall')
			jump_forgiveness(delta)
		
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.05)
	
	# Action/Spellcasting
	if Input.is_action_just_pressed('cast'):
		print("no casting for now")
#		spellCaster.cast()
	
	# Final movement integration
	motion = move_and_slide(motion, UP)

func on_WorldMap_loaded(data):
	var world_map = data.node
	world_map.active_map.random_spawn(self)

func die():
	if not is_dead:
		is_dead = true
#		$Sounds/Scream.play()
		print("dead")
		playAnim("die")
		# Disable child processes so nothing updates further
		for child in get_children():
			if child.name != "Sounds":
				print(child.name)
				child.set_physics_process(false)
				child.set_process(false)

func get_dir_x():
	return dir_x

func height():
	return $CollisionShape2D.shape.height

func hit(damage, source = null):
#	$SanityCaster.drain_sanity(damage)
	print("HIT DAMAGE:", damage, " FROM ", source)
	$MovementHandler.freeze()
	immobile_timer = Timer.new()
	immobile_timer.start(0.5)
	immobile_timer.connect("timeout", self, "_on_Immobile_timer_end")
	motion.y = -200
	motion.x = 400 * sign(source.direction.x if source != null else 0)
	$SanitySplatter.emitting = true
	move_and_slide(motion, UP)
	add_child(immobile_timer)
	print("freeze")

func _on_Immobile_timer_end():
	print("unfreeze")
	$MovementHandler.unfreeze()
	$SanitySplatter.emitting = false
	remove_child(immobile_timer)

func move_down():
	pass

func move_idle():
	pass

func move_left():
	motion.x = max(motion.x - ACCELERATION, -MAX_SPEED)
	$Sprite.flip_h = true
#	dir_x = -1
	direction.x = -1
	playAnim('run', -1, 1.6)

func move_right():
	motion.x += ACCELERATION
	motion.x = min(motion.x + ACCELERATION, MAX_SPEED)
	$Sprite.flip_h = false
#	dir_x = 1
	direction.x = 1
	playAnim('run', -1, 1.6)

func move_up():
#	motion.y = JUMP_HEIGHT
	jump()

func jump():
	if not is_jumping:
		is_jumping = true
	if current_jump_height > JUMP_HEIGHT and motion.y != JUMP_HEIGHT:
		current_jump_height += (JUMP_HEIGHT / 10)
	else:
		current_jump_height = JUMP_HEIGHT
		is_jumping = false
	motion.y = current_jump_height
#	print("jumping", current_jump_height)

func jump_forgiveness(delta):
	if jump_forgiveness_time <= 0:
		jump_forgiveness_time = JUMP_FORGIVENESS
	else:
		jump_forgiveness_time -= delta
		if jump_forgiveness_time <= 0:
			is_falling = true
			is_jumping = false

func playAnim(anim, custom_blend = -1, custom_speed = 1.0):
	if $Sprite/AnimationPlayer.current_animation != anim || !$Sprite/AnimationPlayer.is_playing():
		$Sprite/AnimationPlayer.play(anim, custom_blend, custom_speed)

func set_health(amount):
	$Health.set_health(amount)

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

func width():
	return $CollisionShape2D.shape.radius * 2