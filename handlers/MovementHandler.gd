extends Node

# Not sure if this is where I want to handle this
# but I need a way to prevent player input during
# cinematics, or whenever else I want.
var disable_movement = false setget _private_set,_private_get

# External variable to determine whether handler is allowed to move.
var frozen setget _private_set,_get_frozen
func _get_frozen():
	return disable_movement

# Hmm, should I use an override to replace player input
# instead of fully disabling movement?
# But then it is subject to other overrides in the system...

# Functions stored here run by default
var default_movement = {
	"down": null,
	"idle": null,
	"left": null,
	"right": null,
	"up": null
}

# Functions stored here run in place of the default movement
var override_movement = {
	"down": null,
	"idle": null,
	"left": null,
	"right": null,
	"up": null
}

# Functions stored here run before the current movement
var before_movement = {
	"down": null,
	"idle": null,
	"left": null,
	"right": null,
	"up": null
}

# Functions stored here run after the current movement
var after_movement = {
	"down": null,
	"idle": null,
	"left": null,
	"right": null,
	"up": null
}

func _ready():
	pass

func _private_get():
	print("Private variable")

func _private_set(_throwaway_):
	print("Private variable")

# Set the default movement responses
func set_defaults(defaults = {}):
	for key in defaults:
		if default_movement.has(key):
			default_movement[key] = defaults[key]
		else:
			print("Default movement not found: ", key)

func set_default(default_name, function):
	if default_movement.has(default_name):
		default_movement[default_name] = function
	else:
		print("Default movement not found: ", default_name)

# Handle down movement
func move(direction):
	if disable_movement:
		return
	
	if override_movement[direction] != null:
		override_movement[direction].call_func()
	else:
		default_movement[direction].call_func()

###
# Movement
###

func down():
	if not disable_movement:
		default_movement['down'].call_func() if override_movement['down'] == null else override_movement['down'].call_func()

func idle():
	if not disable_movement:
		default_movement['idle'].call_func() if override_movement['idle'] == null else override_movement['idle'].call_func()

func left():
	if not disable_movement:
		default_movement['left'].call_func() if override_movement['left'] == null else override_movement['left'].call_func()

func right():
	if not disable_movement:
		default_movement['right'].call_func() if override_movement['right'] == null else override_movement['right'].call_func()

func up():
	if not disable_movement:
		default_movement['up'].call_func() if override_movement['up'] == null else override_movement['up'].call_func()

###
# Override functions
###

func set_overrides(overrides = {}):
	for key in overrides:
		if override_movement.has(key):
			override_movement[key] = overrides[key]
		else:
			print("Override movement not found: ", key)

func set_override(override_name, function):
	if override_movement.has(override_name):
		override_movement[override_name] = function
	else:
		print("Override movement not found: ", override_name)

func clear_overrides():
	for key in override_movement:
		override_movement[key] = null

func remove_overrides(overrides = []):
	for key in overrides:
		if override_movement.has(key):
			override_movement[key] = null
		else:
			print("Override movement not found: ", key)

func remove_override(override_name):
	if override_movement.has(override_name):
		override_movement[override_name] = null
	else:
		print("Override movement not found: ", override_name)

# Prevent character from moving via the handler
func freeze():
	disable_movement = true

# Unfreeze
func unfreeze():
	disable_movement = false