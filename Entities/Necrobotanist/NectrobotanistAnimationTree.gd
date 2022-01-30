extends AnimationTree


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	set("parameters/conditions/buried", false)
	set("parameters/conditions/not_buried", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Necrobotanist_walking_started():
	self.set("parameters/Locomotion/conditions/walking", true)
	self.set("parameters/Locomotion/conditions/not_walking", false)


func _on_Necrobotanist_walking_stopped():
	self.set("parameters/Locomotion/conditions/walking", false)
	self.set("parameters/Locomotion/conditions/not_walking", true)


func _on_Necrobotanist_jumped():
	self.set("parameters/Locomotion/conditions/grounded", false)
	self.set("parameters/Locomotion/conditions/rising", true)
	self.set("parameters/Locomotion/conditions/falling", false)


func _on_Necrobotanist_jump_peaked():
	self.set("parameters/Locomotion/conditions/falling", true)
	self.set("parameters/Locomotion/conditions/rising", false)


func _on_Necrobotanist_landed():
	self.set("parameters/Locomotion/conditions/grounded", true)
	self.set("parameters/Locomotion/conditions/falling", false)
	self.set("parameters/Locomotion/conditions/rising", false)


func _on_Necrobotanist_felloff():
	self.set("parameters/Locomotion/conditions/grounded", false)
	self.set("parameters/Locomotion/conditions/falling", true)


func _on_SeedThrower_seed_throw_started():
	var state_machine : AnimationNodeStateMachinePlayback = self.get("parameters/playback")
	state_machine.travel("seed_throw")
