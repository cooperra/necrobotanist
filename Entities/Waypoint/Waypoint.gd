extends Area2D

var occupant = null
export(Array) var connected_waypoints = []


func _ready() -> void:
	pass



# Automated methods to setup waypoint connections
#func _set_connected_waypoints():
#	var groups := get_tree().get_nodes_in_group("waypoint")
#
#
#func _check_if_in_sight(location_a, location_b):
#	var 



func check_if_free():
	if occupant == null:
		return true
	return false


func _on_Waypoint_body_entered(body: Node) -> void:
	if occupant == null:
		var groups := body.get_groups()
		if groups.has("minion") or groups.has("necrobotanist"):
			occupant = body


func _on_Waypoint_body_exited(body: Node) -> void:
	if occupant == body:
		occupant = null
