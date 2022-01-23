extends Node2D


signal level_completed


# Declare member variables here.
export(PackedScene) var next_scene = null
export(bool) var skip_fanfare = false
export(bool) var debug_restart_current_level = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area2D_body_entered(body: Node2D):
	# TODO proper way to check for player collisions
	if body.name == 'Necrobotanist' and not $VictoryFanfare.playing:
		emit_signal("level_completed")
		_on_level_completed()


func _on_level_completed():
	if skip_fanfare:
		_on_VictoryFanfare_finished()
	else:
		$VictoryFanfare.play()

func _on_VictoryFanfare_finished():
	if debug_restart_current_level:
		get_tree().reload_current_scene()
	elif next_scene:
		get_tree().change_scene_to(next_scene)
