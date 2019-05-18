extends Position2D

onready var parent = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	update_pivot_angle()
	pass # Replace with function body.

func _physics_process(delta):
	update_pivot_angle()

func update_pivot_angle():
	rotation = parent.direction.angle()