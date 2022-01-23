extends Node2D


# Declare member variables here.
export(Vector2) var throw_velocity = Vector2(300, -300)
export(float) var throw_angular_velocity = 5.0

export(PackedScene) var seed_scene = preload("res://Entities/Seed/Seed.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

const LEFT = 1
const RIGHT = 0
func _on_Necrobotanist_facing_changed(new_facing):
	match new_facing:
		LEFT:
			self.position.x = -abs(self.position.x)
			throw_velocity.x = -abs(throw_velocity.x)
			throw_angular_velocity = -abs(throw_angular_velocity)
		RIGHT:
			self.position.x = abs(self.position.x)
			throw_velocity.x = abs(throw_velocity.x)
			throw_angular_velocity = abs(throw_angular_velocity)


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("throw_seed"):
		throw_seed()
		get_tree().set_input_as_handled()


func throw_seed():
	var new_seed = seed_scene.instance()
	get_tree().current_scene.add_child(new_seed)
	new_seed.linear_velocity = throw_velocity
	new_seed.angular_velocity = throw_angular_velocity
	new_seed.global_position = self.global_position
