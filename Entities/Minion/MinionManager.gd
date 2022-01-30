extends Node


var minion_list := []
var necrobotanist := PhysicsBody2D
var Minion = preload("res://Entities/Minion/Minion.gd")


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
		match m.ai_state:
			Minion.AIState.FOLLOW:
				m.target_to_follow = previous
				previous = m
			Minion.AIState.CHARGE:
				pass
			Minion.AIState.FERTILIZE:
				pass
			Minion.AIState.RETURN:
				m.target_to_follow = get_closest(m, [necrobotanist] + minion_list)
				if m.position.distance_to(m.target_to_follow.position):
					m.ai_state = Minion.AIState.FOLLOW



func distance_to_player_sort(a: Node2D, b: Node2D):
	if necrobotanist == null:
		return false
	return a.position.distance_squared_to(necrobotanist.position) < b.position.distance_squared_to(necrobotanist.position)


func get_closest(node: Node2D, node_list: Array):
	var closest = null
	for other in node_list:
		if other == node:
			# Skip self
			continue
		if closest == null:
			closest = other
		if other.position.distance_squared_to(node.position) < closest.position.distance_squared_to(node.position):
			closest = other
	return closest


func _on_Timer_timeout() -> void:
	do_full_check()


func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		# Start charge
		# Choose closest following minion
		minion_list.sort_custom(self, "distance_to_player_sort")
		for minion in minion_list:
			if minion.ai_state == Minion.AIState.FOLLOW:
				var charge_direction = -((necrobotanist.facing * 2) - 1)
				minion.start_charge(charge_direction)
				break
		get_tree().set_input_as_handled()
