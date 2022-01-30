extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		for area in get_overlapping_areas():
			if area.is_in_group("plant_root"):
				area.get_parent().minion_unfertilize()
				# It's important that this gets dibs over the charge function on the same key binding
				get_tree().set_input_as_handled()
				break
