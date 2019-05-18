extends "res://spells/Spell.gd"

signal fire_bullet(bullet)

var Fireball = preload('res://entities/bullets/Fireball/Fireball.tscn')

var spell_range = 500
var spell_bullet_speed = 500

func effect():
	.effect()
	
	# Get data to send with the event dispatch
	#var Player = root.get_node('Player')
	var Player = Spellcaster.Caster
	var pos = Player.position + Vector2(0, Player.height / 2)
	var pos_to = Vector2(pos.x + (spell_range * -Player.dir_x), pos.y)
	var angle = pos.angle_to_point(pos_to)
	var dir = Vector2(cos(angle), sin(angle))
	
	EventBus.dispatch('add_bullet', {
		'Bullet': Fireball,
		'origin': pos,
		'direction': dir,
		'speed': spell_bullet_speed,
		'collision_exceptions': [
			Player
		]
	})
	$AudioStreamPlayer.play()
	print('Fireball fired!')
