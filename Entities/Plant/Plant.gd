extends Node2D


# Declare member variables here.
var current_tip : Node2D
export(PackedScene) var stem_segment_scene = preload("res://Entities/Plant/StemSegment.tscn")
export(int) var pending_growth = 1
export(int) var growth_level = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Find the current tip
	current_tip = $SproutSprite.get_child(0)
	var stem_count = 0
	while current_tip.get_child_count() > 0:
		current_tip = current_tip.get_child(0)
		stem_count += 1
	# If growth_level is more than we've actually grown so far, catch up
	if growth_level > 0:
		# Set frame to fully sprouted
		$SproutSprite.frame = 3
	while growth_level > stem_count+1:
		_add_stem_segment()
		stem_count += 1
	check_growth()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func check_growth():
	if pending_growth > 0:
		pending_growth -= 1
		grow()


func grow():
	if growth_level == 0:
		$AnimationPlayer.play("sprout")
	else:
		$AnimationPlayer.play("grow")
	growth_level += 1


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
