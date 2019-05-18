extends Timer

export(float) var age_damage = 10

onready var player = get_parent().get_node("WorldMap").get_node("Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Player ages, aka loses some time from their life.
func age_player():
	if not player.is_dead:
		player.hit(age_damage)

func _on_PassageOfTime_timeout():
	age_player()
	start()
