extends Node2D


# Declare member variables here.
var current_tip : Node2D
export(PackedScene) var stem_segment_scene = preload("res://Entities/Plant/StemSegment.tscn")
export(PackedScene) var stem_leaf_scene = preload("res://Entities/Plant/Leaf.tscn")
export(int) var pending_growth = 1  # seed instantly becomes sprout
export(int) var growth_level = 0
export(int) var next_leaf_goes_left = -1  # random

const Minion = preload("res://Entities/Minion/Minion.gd")
var minions_consumed = []


# Called when the node enters the scene tree for the first time.
func _ready():
	# Find the current tip
	current_tip = $SproutSprite.get_child(0)
	var stem_count = 0
	while current_tip.get_child_count() > 0:
		current_tip = current_tip.get_child(0)
		stem_count += 1

	# Randomize leaf direction if needed
	if next_leaf_goes_left == -1:
		next_leaf_goes_left = bool(randi() % 2)

	# If growth_level is more than we've actually grown so far, instantly grow to catch up
	if growth_level > 0:
		# Set frame to fully sprouted
		$SproutSprite.frame = 3
	while growth_level > stem_count+1:
		_add_stem_segment()
		_add_next_leaf()
		stem_count += 1
	check_growth()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func check_growth():
	if pending_growth > 0 and not $AnimationPlayer.is_playing():
		pending_growth -= 1
		grow()
	elif pending_growth < 0 and not $AnimationPlayer.is_playing():
		pending_growth += 1
		shrink()


func grow():
	if growth_level == 0:
		$AnimationPlayer.play("sprout")
	else:
		$AnimationPlayer.play("grow")
		if not $AudioStreamPlayer2D.playing:
			$AudioStreamPlayer2D.play()
	growth_level += 1


func shrink():
	if growth_level == 0:
		# Can't shrink further
		queue_free()
	elif growth_level == 1:
		# Ungrow sprout
		$AnimationPlayer.play_backwards("sprout")
	else:
		_remove_stem_segment()
		if not $AudioStreamPlayer2D.playing:
			$AudioStreamPlayer2D.play()  # There's no play_backwards for this
		call_deferred("check_growth")
	growth_level -= 1


func _add_stem_segment():
	# Replace the current tip with a new stem segment
	var new_stem_segment = stem_segment_scene.instance()
	new_stem_segment.position = current_tip.position
	# Add the new tip
	var tip_parent = current_tip.get_parent()
	tip_parent.add_child(new_stem_segment)
	# Update current_tip
	var old_tip = current_tip
	current_tip = new_stem_segment.get_child(0)
	# Remove old tip
	old_tip.queue_free()


func _add_next_leaf():
	# Create new leaf
	var new_leaf = stem_leaf_scene.instance()
	var current_stem = current_tip.get_parent()
	if next_leaf_goes_left:
		new_leaf.position = current_stem.get_node("LeafLPlaceholder").position
	else:
		new_leaf.position = current_stem.get_node("LeafRPlaceholder").position
	# Attach leaf
	current_stem.add_child(new_leaf)
	# Swap direction for next time
	next_leaf_goes_left = not next_leaf_goes_left


func _remove_stem_segment():
	# Remove the current tip's stem and replace with its tip
	var current_stem = current_tip.get_parent()
	var parent_stem = current_stem.get_parent()
	# Remove the current tip
	current_stem.remove_child(current_tip)
	current_tip.position = current_stem.position
	parent_stem.add_child_below_node(current_stem, current_tip)
	parent_stem.remove_child(current_stem)
	current_stem.queue_free()
	# Special case at bottom where we don't want the tip sprite, but do want a placeholder entity present
	if parent_stem.name == "SproutSprite":
		current_tip.hide()


func fertilize(amount: int):
	# Add amount of fertilizer
	pending_growth += amount
	check_growth()


func _on_PlantRoot_area_entered(area : Area2D):
	if area.get_collision_layer_bit(5):  # interactor
		# Start flashing
		$FlashyTween.interpolate_property(self, "modulate",
			Color(1, 1, 1, 1),
			Color(0.5, 0.5, 0.5, 1),
			0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
		$FlashyTween.start()


func _on_PlantRoot_area_exited(area: Area2D):
	if area.get_collision_layer_bit(5):  # interactor
		# Stop flashing
		$FlashyTween.stop_all()
		modulate = Color(1, 1, 1, 1)


func _on_PlantRoot_body_entered(body):
	if body.get_collision_layer_bit(2):  # minion
		var minion : Minion = body
		if minion.ai_state == Minion.AIState.FERTILIZE or minion.ai_state == Minion.AIState.CHARGE:
			minion_fertilize(minion)


func minion_fertilize(minion : Minion):
	minion.bury()
	minions_consumed.push_back(minion)
	if growth_level == 0:
		# Getting to sprout is free
		fertilize(2)
	else:
		fertilize(1)


func minion_unfertilize():
	var minion : Minion = minions_consumed.pop_back()
	if is_instance_valid(minion):
		minion.unbury()
	fertilize(-1)
