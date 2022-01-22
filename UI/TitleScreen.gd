extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Give keyboard focus to the start button
	$VBoxContainer/StartButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartButton_pressed():
	get_tree().change_scene("res://Levels/TestLevel/TestLevel.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()
