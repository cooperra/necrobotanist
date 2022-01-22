extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set visibility to current pause state
	self.visible = get_tree().paused


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# Handle pause button input
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		var tree = get_tree()
		if self.visible:
			_on_ResumeButton_pressed()
		else:
			_on_PauseButton_pressed()
		tree.set_input_as_handled()


func _on_PauseButton_pressed():
	get_tree().paused = true
	self.show()
	$VBoxContainer/ResumeButton.grab_focus()


func _on_ResumeButton_pressed():
	self.hide()
	get_tree().paused = false


func _on_RestartButton_pressed():
	get_tree().reload_current_scene()
	get_tree().paused = false


func _on_QuitButton_pressed():
	get_tree().change_scene("res://UI/TitleScreen.tscn")
	get_tree().paused = false
