extends "res://spells/Spell.gd"

export(float) var spell_range = 100.00

export (int) var detect_radius = 100
var vis_color = Color(.867, .91, .247, 0.1)
var laser_color = Color(1, 0, 0, 1)

var target
var hit_pos = position
var spell_direction

func effect():
	.effect()
	var player = Spellcaster.Caster
	var direction = player.direction
	var pos = player.position
#	position = pos
	var spell_direction = (spell_range * direction) + player.position
	target = spell_direction
	var collision = $CollisionLayer.collision_mask
	
	#var space_state = player.get_world_2d().direct_space_state
	#var result = space_state.intersect_ray(player.position, spell_direction, [self, player], collision) # 61 is collision mask for everything except tilemap
	var result = castRay(player, spell_direction, collision)
#	breakpoint
	if result:
		spell_direction = result.position - (Vector2(player.width, player.height) * player.direction)
	else:
		hit_pos = spell_direction
	player.position = spell_direction
	$Sounds/Teleport.play()

func castRay(player, spell_direction, collision):
	var space_state = player.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(player.position, spell_direction, [self, player], collision) # 61 is collision mask for everything except tilemap
	return result

# Only needed when debugging the range.
#func _physics_process(delta):
#	update()

func _draw():
	return
	target = Spellcaster.Caster
#	print("player ", player.position)
	hit_pos = (spell_range * target.direction) + target.position
	var result = castRay(target, hit_pos, $CollisionLayer.collision_mask)
	if result:
		hit_pos = result.position - (Vector2(target.width, target.height) * target.direction)
	draw_circle(target.position, detect_radius, vis_color)
	draw_line(target.position, (hit_pos), laser_color)
	draw_circle((hit_pos), 5, laser_color)