extends Node
export var current = 10
export var maximum = 10
export var invincible = false

var invincibility_duration = 0
var invincibility_remaining = 0

func _physics_process(delta):
	if invincibility_remaining > 0:
		invincibility_remaining -= delta

func full_heal():
	current = maximum

func heal(amount):
	current = current + amount if maximum - amount > current else maximum
	
func hurt(amount):
	if not invincible:
		current = current - amount if current - amount > 0 else 0

func make_invincible(duration = 3):
	if not invincible:
		invincible = true
		invincibility_duration = duration
		invincibility_remaining = duration

func set_health(amount):
	current = amount