extends KinematicBody2D

signal landed  # emitted upon landing on the ground
signal jumped  # emitted when a jump begins
signal jump_peaked  # emitted when hitting the peak of a jump
signal ceiling_bonked  # emitted when bonking a ceiling (jump_peaked will not emit when this happens)
signal felloff  # emitted when ground is no longer underfoot, but we didn't jump (e.g. walkoff)
signal facing_changed  # emitted when the character turns around (the new facing direction is passed as an arg)
signal walking_started  # emitted when the character starts walking (even in air)
signal walking_stopped  # emitted when the character stops lateral movement

enum JumpState {GROUNDED, RISING, FALLING}
enum Facing {LEFT, RIGHT}

# Physics state
export var velocity := Vector2(0, 0)
export(JumpState) var jump_state := JumpState.FALLING
export var up_direction := Vector2(0, -1)

# Animation state
export(Facing) var facing := Facing.RIGHT
export var is_walking := false

# Lateral motion parameters
export var WALK_MAX_SPEED = 300
export var WALK_START_SPEED = 130
export var WALK_ACCEL = 300

# Jumping parameters
export var JUMP_HEIGHT = 120
export var JUMP_RISE_TIME = 0.5
# https://urodelagames.github.io/2021/09/29/godot-tweens-by-example/#transition-types-and-ease-types
export var JUMP_TRANS_TYPE = Tween.TRANS_QUART
export var JUMP_EASE_TYPE = Tween.EASE_OUT

# Falling parameters
export var FALL_MAX_SPEED = 600
export var FALL_START_SPEED = 200
export var FALL_ACCEL = 900

# AI information
var input := Vector2(0, 0)
export var STOP_DISTANCE := 60
var target_to_follow: Node2D
var jitter_stop := false
var jitter_stop_target_pos := Vector2.ZERO
var debug_status_text := "Chase"
var stuck := false
var STUCK_DISTANCE := 10
var stuck_location := Vector2.ZERO
enum AIState {
	FOLLOW, # Make a conga line behind the Necrobotanist
	CHARGE, # Run forward for a while. FERTILIZE any nearby seed or RETURN after a time.
	FERTILIZE, # Decay and become dormant, increasing the plant's growth level.
	BURIED, # Do nothing
	RETURN # Go to the nearest minion or necrobotonist, then return to FOLLOW once nearby.
}
var ai_state = AIState.FOLLOW
var charge_direction_x = 0


func _ready() -> void:
	pass


func _physics_process(delta):
	update_debug_labels()
	process_ai(delta)
	handle_horiz_input(delta)
	handle_jump_state(delta)
	velocity = move_and_slide_with_snap(velocity, up_direction.rotated(PI), up_direction)
	handle_collisions()


func update_debug_labels():
	get_node("Debug/Name").text = "Name: " + str(name)
	if is_instance_valid(target_to_follow):
		get_node("Debug/Target").text = debug_status_text + str(target_to_follow.name)
	else:
		get_node("Debug/Target").text = debug_status_text + "<invalid>"
	$Debug/AIState.text = str(ai_state)


func process_ai(delta):
	match ai_state:
		AIState.FOLLOW:
			follow_target()
		AIState.CHARGE:
			input = Vector2.ZERO
			input.x = charge_direction_x
			if is_on_wall():
				# Jump
				input.y = 1
		AIState.FERTILIZE:
			follow_target()
		AIState.BURIED:
			input = Vector2.ZERO
		AIState.RETURN:
			follow_target()


func follow_target():
	input = Vector2.ZERO
	if not is_instance_valid(target_to_follow):
		return
	# Jump if stuck
	if stuck and not jitter_stop:
		input.y = 1
		if target_to_follow.position.x < position.x:
			input.x = -1
		elif target_to_follow.position.x > position.x:
			input.x = 1
		debug_status_text = "Jumping To: "
		return
	# Do not move if target stuck in the same general area
	if jitter_stop:
		debug_status_text = "Still: "
		return
	debug_status_text = "Chase: "
	if target_to_follow == null:
#		input = Vector2.ZERO
		return
	var within_stop_distance = (target_to_follow.position - position).abs().length() <= STOP_DISTANCE
	# Move to the side if on top of target
#	if target_to_follow.position.y > position.y and within_stop_distance:
#		if target_to_follow.position.x <= position.x:
#			input.x = -0.5
#		elif target_to_follow.position.x > position.x:
#			input.x = 0.5
	# If within stop distance, stop
	if within_stop_distance:
#		input = Vector2.ZERO
		return
	# Move to the left or right towards target
	if target_to_follow.position.x < position.x:
		input.x = -1
	elif target_to_follow.position.x > position.x:
		input.x = 1
	# Jump if the target is higher up
	# Added some leeway
	if target_to_follow.position.y + 30 < position.y:
		input.y = 1
	# Currently no need for shifting movement down other than by falling
#	elif target_to_follow.position.y > position.y:
#		input.x = -0.5


func handle_horiz_input(delta):
	var horiz_axis = input.x
	# Start with a minimum speed and accelerate from there
	if horiz_axis > 0:
		velocity.x = max(velocity.x, WALK_START_SPEED)
		if facing == Facing.LEFT:
			facing = Facing.RIGHT
			emit_signal("facing_changed", facing)
	elif horiz_axis < 0:
		velocity.x = min(velocity.x, -WALK_START_SPEED)
		if facing == Facing.RIGHT:
			facing = Facing.LEFT
			emit_signal("facing_changed", facing)
	# Accelerate
	velocity.x += horiz_axis * WALK_ACCEL * delta
	# Clamp to max speed
	velocity.x = clamp(velocity.x, -abs(horiz_axis) * WALK_MAX_SPEED, abs(horiz_axis) * WALK_MAX_SPEED)
	# Update is_walking state for animations
	if is_walking != (velocity.x != 0):
		is_walking = velocity.x != 0
		if is_walking:
			emit_signal("walking_started")
		else:
			emit_signal("walking_stopped")


func handle_jump_state(delta):
	match jump_state:
		JumpState.FALLING:
			# Fall at least this fast
			velocity.y = max(velocity.y, FALL_START_SPEED)
			# Accelerate
			velocity.y += FALL_ACCEL * delta
			# Clamp terminal velocity
			velocity.y = min(velocity.y, FALL_MAX_SPEED)
		JumpState.RISING:
			# Check for tween finished
			if not $JumpTween.is_active():
				jump_state = JumpState.FALLING
				emit_signal("jump_peaked")
		JumpState.GROUNDED:
			# TODO Check to see if we've fallen off a platform  # TODO emit felloff
			if input.y > 0:
				# Begin jump

				# Let minions jump twice as high when they are stuck
				var mult = 1
				if stuck:
					mult = 2

				var jump_peak_y = position.y - JUMP_HEIGHT * mult
				$JumpTween.interpolate_property(self, "position:y", position.y,
					jump_peak_y, JUMP_RISE_TIME, JUMP_TRANS_TYPE, JUMP_EASE_TYPE)
				$JumpTween.start()
				jump_state = JumpState.RISING
				emit_signal("jumped")


func handle_collisions():
	# For collision debugging
#	for i in get_slide_count():
#		var collision = get_slide_collision(i)
#		print("Collided with: ", collision.collider.name)

	# Check for bonking on ceiling
	if jump_state == JumpState.RISING and is_on_ceiling():
		jump_state = JumpState.FALLING
		# Cancel any existing jump tween
		$JumpTween.stop_all()
		# Cancel all upward momentum (even though jump currently doesn't touch velocity)
		velocity.y = 0
		emit_signal("ceiling_bonked")
	# Check for landing
	if jump_state == JumpState.FALLING and is_on_floor():
		jump_state = JumpState.GROUNDED
		# Cancel downward momentum
		velocity.y = 0
		emit_signal("landed")
	# Check for walk-off or disappeared platform
	if jump_state == JumpState.GROUNDED and not is_on_floor():
		jump_state = JumpState.FALLING
		emit_signal("felloff")


func _on_JitterCheck_timeout() -> void:
	if is_instance_valid(target_to_follow):
		if target_to_follow.position.is_equal_approx(jitter_stop_target_pos):
			pass #jitter_stop = true
		else:
			jitter_stop_target_pos = target_to_follow.position
			#jitter_stop = false
	if is_on_wall():
		stuck = true
	else:
		stuck = false


func start_charge(direction_x):
	charge_direction_x = direction_x
	ai_state = AIState.CHARGE
	target_to_follow = null
	$ReturnTimer.start()


func _on_ReturnTimer_timeout():
	if ai_state == AIState.CHARGE:
		ai_state = AIState.RETURN
		target_to_follow = null


func bury():
	ai_state = AIState.BURIED
	$AnimationTree.set("parameters/conditions/buried", true)
	$AnimationTree.set("parameters/conditions/not_buried", false)


func unbury():
	ai_state = AIState.FOLLOW
	$AnimationTree.set("parameters/conditions/buried", false)
	$AnimationTree.set("parameters/conditions/not_buried", true)
