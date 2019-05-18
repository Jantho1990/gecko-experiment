extends Node2D

const _class_name = "Spell"

export(float) var cost = 20
export(float) var cooldown = 0.25

enum hotkeyEnum {
	HK1 = 1,
	HK2 = 2,
	HK3 = 3,
	HK4 = 4,
	HK5 = 5,
	HK6 = 6,
	HK7 = 7,
	HK8 = 8,
	HK9 = 9,
	HK0 = 0
}
export(hotkeyEnum) var hotkey


onready var last_fired = cooldown
var fired = false

# Set the Spellcaster
# This makes the assumption that a spell will always be added
# as a direct child of a Spellcaster node.
onready var Spellcaster = get_parent()

onready var spell_name = name

func can_cast(mana_current):
	if has_enough_mana(cost, mana_current) && has_cooled_down(cooldown, last_fired):
		return true
	return false

func has_enough_mana(cost, available):
	return cost <= available

func has_cooled_down(cooldown, last_fired):
	return last_fired >= cooldown

func effect():
	fired = true
	last_fired = 0
	Spellcaster.mana_current -= cost

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _physics_process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	if fired:
		last_fired += delta
	
	if fired && last_fired >= cooldown:
		fired = false
