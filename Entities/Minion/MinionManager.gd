extends Node


var minion_list := []
var necrobotanist := PhysicsBody2D


func _ready() -> void:
	do_full_check()
	pass


func do_full_check():
	update_necrobotanist()
	update_minion_list()
	update_minion_targets()


func update_necrobotanist():
	necrobotanist = get_tree().get_nodes_in_group("necrobotanist").front()


func update_minion_list():
	minion_list.clear()
	minion_list = get_tree().get_nodes_in_group("minion")


func update_minion_targets():
	minion_list.sort_custom(self, "distance_to_player_sort")
	# Debug print based on distance to player
#	for m in minion_list:
#		print(m.name)
	var previous = necrobotanist
	for m in minion_list:
		m.target_to_follow = previous
		previous = m


func distance_to_player_sort(a: Node2D, b: Node2D):
	if necrobotanist == null:
		return false
	return a.position.distance_squared_to(necrobotanist.position) < b.position.distance_squared_to(necrobotanist.position)


func _on_Timer_timeout() -> void:
	do_full_check()
