extends KinematicBody2D


export var fertilizer_per_stage := 1 # 1 zombie per stage

var fertilization_level := 0
var stage := 0 # 0 is seed/sprout/non-platform; 1 and above are platform states


func _ready() -> void:
	pass


func fertilize(amount: int):
	# Add anount of fertilizer
	fertilization_level += amount
	# If there is enough, subtracts sufficient fertilizer
	var count = 0
	while fertilization_level >= fertilizer_per_stage:
		fertilization_level -= fertilizer_per_stage
		count += 1
	grow(count)


func grow(amount: int):
	var count = 0
	while count < amount:
		# Increase sprite size by adding another segment
		# TODO
		# Recalculate collider if needed
		# TODO
		# Consider a yield timer here to have it occur over time
		count += 1
		stage += 1
