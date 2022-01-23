extends KinematicBody2D

# These signals should help with animation
# Signals guide: https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
signal landed  # emitted upon landing on the ground
signal jumped  # emitted when a jump begins
signal jump_peaked  # emitted when hitting the peak of a jump
signal ceiling_bonked  # emitted when bonking a ceiling (jump_peaked will not emit when this happens)
signal felloff  # emitted when ground is no longer underfoot, but we didn't jump (e.g. walkoff)
signal facing_changed  # emitted when the character turns around (the new facing direction is passed as an arg)
signal walking_started  # emitted when the character starts walking (even in air)
signal walking_stopped  # emitted when the character stops lateral movement

enum JumpState {GROUNDED, RISING, FALLING}
enum Facing {RIGHT, LEFT}

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


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	handle_horiz_input(delta)
	handle_jump_state(delta)
	velocity = move_and_slide_with_snap(velocity, up_direction.rotated(PI), up_direction)
	handle_collisions()


func handle_horiz_input(delta):
	var horiz_axis = Input.get_axis("move_left", "move_right")
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
			if Input.is_action_just_pressed("jump"):
				# Begin jump

				# Handy debug way to get extra-height
				var mult = 1
				if Input.is_action_pressed("ui_up"):
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
