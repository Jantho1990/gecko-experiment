extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(float) var mana_total = 100
export(float) var mana_current = 100
export(float) var recharge_amount = 20
export(float) var recharge_rate = 1

var recharge_time = 0

#export(String, 'Red', 'Fireball', 'Levitate', 'Shield') var spellNames
export(NodePath) var active_spell setget set_active_spell,get_active_spell

# not sure we need this if Godot is already updating children for us
onready var spells = get_spells()

# Set the parent as the Caster of spells.
# This makes the assumption that Spellcaster will always be added as
# a direct child of an entity that can cast spells.
onready var Caster = get_parent()

func get_spells():
	var ret = []
	var children = get_children()
	for child in get_children():
		if child.get("_class_name") != null and child._class_name == "Spell":
			ret.push_back(child)
	return ret

# Attempt to cast a spell
func cast():
	print("casting")
	print(active_spell, " is active")
	if typeof(active_spell) == TYPE_NODE_PATH and active_spell.is_empty():
		print("welp")
		return
	
	if active_spell == null:
		return
		
	var spell = active_spell
	
	if spell.can_cast(mana_current):
		spell.effect()
		print("can cast")
	else:
		# notify user that they can't cast the spell
		print("Cannot cast")
		pass

# Recharge the spellcaster's mana
func recharge(delta):
	recharge_time += delta
	if recharge_time >= recharge_rate:
		mana_current += recharge_amount
		recharge_time -= recharge_rate
	
	if mana_current > mana_total:
		mana_current = mana_total
	
#	EventBus.dispatch("update_ui_sanity", {
#		"current": mana_current
#	})

func _input(event):
	# Switch active spell if hotkey is being pressed.
	if event.is_action_pressed("spell_hotkey"):
		switch_active_spell(int(event.as_text()))
	elif event.is_action_released("spell_hotkey"):
		after_switch_active_spell(int(event.as_text()))

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	if active_spell != null and !active_spell.is_empty():
		active_spell = get_node(active_spell)

func _physics_process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	recharge(delta)

# Find a spell using any key and value.
func find_spell(key, value):
	for spell in spells:
		if spell[key] == value:
			return spell
	return null

# Switch the active spell.
func switch_active_spell(hotkey):
	if active_spell == null or active_spell.hotkey != hotkey:
		self.active_spell = find_spell("hotkey", hotkey)

# Callback after active spell is switched.
func after_switch_active_spell(hotkey):
	pass

# Handle switching active spell and dispatching related events.
func set_active_spell(spell):
	if typeof(spell) == TYPE_NODE_PATH and spell.is_empty():
		return
		
	if spell != null:
		active_spell = spell
		if typeof(active_spell) != TYPE_NODE_PATH:
			EventBus.dispatch("update_ui_spell_slot", {
				"spell_name": active_spell.name,
				"selected": true
			})

func get_active_spell():
	return active_spell