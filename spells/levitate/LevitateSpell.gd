extends "res://spells/Spell.gd"

export(float) var duration = 2

var LevitateBuff = preload('res://entities/buffs/Levitate/LevitateBuff.tscn')

func effect():
	.effect()
	
	# Set up data for event dispatch
	var target = Spellcaster.Caster
	
	EventBus.dispatch('add_buff', {
		"Buff": LevitateBuff,
		"target": target,
		"duration": duration
	})
	print("Levitate fired!")