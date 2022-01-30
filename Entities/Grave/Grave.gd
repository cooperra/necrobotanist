extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var has_minion = true
const MinionScn = preload("res://Entities/Minion/Minion.tscn")
const Minion = preload("res://Entities/Minion/Minion.gd")
const spawn_offset := Vector2(0, -40)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func on_interact():
	if has_minion:
		spawn_minion()
		has_minion = false
		# Stop flashing
		$FlashyTween.stop_all()
		modulate = Color(1, 1, 1, 1)
		return true
	return false


func spawn_minion():
	var minion = MinionScn.instance()
	minion.position = position + spawn_offset
	minion.ai_state = Minion.AIState.FOLLOW
	get_tree().current_scene.add_child(minion)


func _on_Grave_area_entered(area : Area2D):
	if area.get_collision_layer_bit(5) and has_minion:  # interactor
		# Start flashing
		$FlashyTween.interpolate_property(self, "modulate",
			Color(1, 1, 1, 1),
			Color(0.5, 0.5, 0.5, 1),
			0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
		$FlashyTween.start()


func _on_Grave_area_exited(area: Area2D):
	if area.get_collision_layer_bit(5):  # interactor
		# Stop flashing
		$FlashyTween.stop_all()
		modulate = Color(1, 1, 1, 1)
