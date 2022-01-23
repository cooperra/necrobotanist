extends RigidBody2D


# Declare member variables here.
export(PackedScene) var sprout_scene = preload("res://Entities/Plant/Plant.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _physics_process(delta):
	# Fade-out and destroy slow-moving seeds
	if linear_velocity.length_squared() < 10000 and not $FadeOut.is_active():
		$FadeOut.interpolate_property(self, "modulate:a", 1, 0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		$FadeOut.start()


func _integrate_forces(state: Physics2DDirectBodyState):
	try_to_plant(state)


func try_to_plant(state: Physics2DDirectBodyState):
	# Check if we're touching a plantable surface that isn't already planted
	for i in state.get_contact_count():
		# Suppress all planting if there's already a plant planted at our location
		for area in $Area2D.get_overlapping_areas():
			if area.is_in_group("plant_root"):
				return false
		# We've hit something. Try to plant in it.
		# Ignore everything but plantable
		var other = state.get_contact_collider_object(i)
		if other is Node and other.is_in_group("plantable"):
			# Now check the normal. We don't support planting into sides of tiles
			var normal: Vector2 = state.get_contact_local_normal(i)
			if abs(normal.angle_to(Vector2(0, -1))) < deg2rad(45):
				#print("Current Seed Pos: " + str(position))
				#print("Contact Local Pos: " + str(state.get_contact_local_position(i)))
				# Seems like it's actually a global position already. How weird
				var sprout_pos = state.get_contact_local_position(i)
				#print("Contact Global pos: " + str(sprout_pos))
				plant(sprout_pos)
				queue_free()
				# If parallel edges collide, it generates two collisions, so return early if we plant
				return true
	return false


func plant(sprout_pos):
	var new_sprout = sprout_scene.instance()
	get_tree().current_scene.add_child(new_sprout)
	new_sprout.global_position = sprout_pos
	#print("New Spout Pos: " + str(new_sprout.position))
	#print("New Spout Global Pos: " + str(new_sprout.global_position))
