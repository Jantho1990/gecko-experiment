extends Node

export(Array, String, FILE, "*.tscn") var endgame_scenes = []

# Explicitly ties this to a root scene.
# Don't like it, but I don't want to waste time
# figuring out how to abstract it, at least for
# the moment.
onready var current_scene = get_parent()

onready var AnimationPlayer = $AnimationPlayer

var to_scene

func _ready():
	AnimationPlayer.connect("animation_finished", self, "on_Animation_finished")

func find_scene(target_scene):
	for scene in endgame_scenes:
		if scene.find(target_scene) != -1:
			return true
	return false

func change_scene(to_scene, transition = "dissolve"):
	var endgame_scene = find_scene(to_scene)
	if not endgame_scene:
		print("Endgame scene ", to_scene, " not found")
		return
	
	var from_scene = current_scene
	to_scene = load(endgame_scene).instance()
	
	match transition:
		"dissolve":
			dissolve_to_scene(from_scene, to_scene)
		_:
			print("Unknown transition ", transition)

func dissolve_to_scene(from_scene, to_scene):
	var anim = Animation.new()
	anim.name = "change_scene"
	
	# From scene track
	var idx_from = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(idx_from, from_scene.path + ":visibility/opacity")
	anim.track_insert_key(idx_from, 0.0, 1.0)
	anim.track_insert_key(idx_from, 1.0, 0.0)
	
	# To scene track
	var idx_to = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(idx_to, to_scene.path + ":visibility/opacity")
	anim.track_insert_key(idx_to, 0.0, 0.0)
	anim.track_insert_key(idx_to, 1.0, 1.0)
	
	AnimationPlayer.add_animation(anim)
	AnimationPlayer.play(anim.name)

func on_Animation_finished():
	current_scene.get_tree().change_scene(to_scene.path)