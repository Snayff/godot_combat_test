## apply forces to the attached physics node
@icon("res://components/functionals/physics_movement.png")
class_name PhysicsMovementComponent
extends Node


#region SIGNALS

#endregion


#region ON READY

#endregion


#region EXPORTS
@export_group("Component Links")
## the body to apply forces to
@export var _root: PhysicsBody2D
@export_group("Details")
## divert logic to respond to controls rather than targeting
@export var is_attached_to_player: bool = false
#endregion


#region VARS
## an actor to use as a target destination.
##
## only used on initial setting unless `_is_following_target_actor == true`
var _target_actor: Actor
##  a fixed point to move towards
var _target_destination: Vector2 = Vector2.ZERO
var _target_direction: Vector2 = Vector2.ZERO
## the position current moving towards.
var _current_target_pos: Vector2 = Vector2.ZERO
## whether to update _current_target_pos to targets current position
var _is_following_target_actor: bool = false
## which targeting to use
##
## "destination" or "actor"
var _target_mode: Constants.MOVEMENT_TARGET_MODE = Constants.MOVEMENT_TARGET_MODE.none
## how long to reside in the _target_mode = "direction"
var _move_in_direction_duration: float = 0.0
## max movement speed. with max_speed < accel < deccel we can get some random sidewinding movement,
## but still hit target. with move_speed >= accel we move straight to target
var max_speed: float
## how quickly we accelerate. uses delta, so will apply ~1/60th per frame to the velocity,
## up to max_speed.
var acceleration: float
## how quickly we decelerate. uses delta, so will apply ~1/60th per frame to the velocity.
## applied when max_speed is hit. should be >= acceleration.
var deceleration: float
## whether setup() has been called
var _has_run_setup: bool = false
#endregion


#region FUNCS

##########################
####### LIFECYCLE #######
########################

func setup(max_speed_: float, acceleration_: float, deceleration_: float) -> void:
	max_speed = max_speed_
	acceleration = acceleration_
	deceleration = deceleration_

	_has_run_setup = true

func _process(delta: float) -> void:
	# count down duration of move in direction
	_move_in_direction_duration -= delta
	if _move_in_direction_duration <= 0 and _target_mode == Constants.MOVEMENT_TARGET_MODE.direction:
		_target_mode = Constants.MOVEMENT_TARGET_MODE.none

# TODO: eventually, this should just be the _physics process, so that it doesnt need to be called.
## update the physics state's velocity. won't run until setup() has been called.
func execute_physics(delta: float) -> void:
	if not _has_run_setup:
		return

	# not moving towards anything, so slow down to zero
	if _target_mode == Constants.MOVEMENT_TARGET_MODE.none:
		_decelerate_until_stop(delta)
		return

	# get current position to move towards
	if _target_mode == Constants.MOVEMENT_TARGET_MODE.actor and _target_actor is Actor:
		_current_target_pos = _target_actor.global_position

	elif _target_mode == Constants.MOVEMENT_TARGET_MODE.destination:
		_current_target_pos = _target_destination

	elif _target_mode == Constants.MOVEMENT_TARGET_MODE.direction:
		_current_target_pos = _target_direction * max_speed


	# get direction to move to current target pos
	var movement_direction: Vector2 = _root.global_position.direction_to(_current_target_pos)

	# if direction is 0 then slow down
	if movement_direction.is_zero_approx():
		_decelerate_until_stop(delta)
		return

	# move towards target
	var movement: Vector2 = movement_direction * acceleration * delta
	_root.apply_impulse(movement, _root.global_position)

	# debug to show where we're moving
	#HyperLog.sketch_arrow(_root.global_position, movement, delta + 0.1)


##########################
####### PUBLIC  #########
########################


# TODO: remove and fold into physics process/execute physics above, so player uses same
## convert input into velocity
func apply_input_velocity(state: PhysicsDirectBodyState2D) -> void:
	var velocity: Vector2 = state.get_linear_velocity()
	var step: float = state.get_step()

	# get player input.
	if is_attached_to_player:
		var move_left := Input.is_action_pressed(&"move_left")
		var move_right := Input.is_action_pressed(&"move_right")
		var move_up := Input.is_action_pressed(&"move_up")
		var move_down := Input.is_action_pressed(&"move_down")

		velocity = _get_input_velocity(velocity, step, move_left, move_right, move_up, move_down)

	# apply gravity and set back the linear velocity.
	velocity += state.get_total_gravity() * step
	state.set_linear_velocity(velocity)

func set_target_actor(actor: Actor, is_following: bool) -> void:
	if _is_following_target_actor:
		_is_following_target_actor = is_following
		_target_actor = actor
		_target_mode = Constants.MOVEMENT_TARGET_MODE.actor
	else:
		_target_destination = actor.global_position
		_target_mode = Constants.MOVEMENT_TARGET_MODE.destination

func set_target_destination(destination: Vector2) -> void:
	_target_destination = destination
	_target_mode = Constants.MOVEMENT_TARGET_MODE.destination

## set a direction to move in, for the specified duration.
##
## does nothing if duration <= 0
func set_target_direction(direction: Vector2, duration: float) -> void:
	if duration <= 0:
		return

	_target_direction = direction
	_move_in_direction_duration = duration
	_target_mode = Constants.MOVEMENT_TARGET_MODE.direction

##########################
####### PRIVATE #########
########################

## apply deceleration until stopped
func _decelerate_until_stop(delta: float) -> void:
	var current_velocity: Vector2 = _root.linear_velocity

	if current_velocity.is_zero_approx():
		_root.linear_velocity = Vector2.ZERO

	var slow_down_force: Vector2 = Vector2.ZERO
	var set_x_zero: bool = false
	if current_velocity.x > 0:
		if current_velocity.x < deceleration * delta:
			set_x_zero = true
		else:
			slow_down_force.x = -min(current_velocity.x, deceleration * delta)

	elif current_velocity.x < 0:
		if current_velocity.x > -deceleration * delta:
			set_x_zero = true
		else:
			slow_down_force.x = max(current_velocity.x, deceleration * delta)

	var set_y_zero: bool = false
	if current_velocity.y > 0:
		if current_velocity.y < deceleration *delta:
			set_y_zero = true
		else:
			slow_down_force.y = -min(current_velocity.x, deceleration * delta)

	elif current_velocity.y < 0:
		if current_velocity.y > -deceleration * delta:
			set_y_zero = true
		else:
			slow_down_force.y = max(current_velocity.y, deceleration * delta)

	# apply slowdown
	_root.apply_impulse(slow_down_force, _root.global_position)

	if set_x_zero:
		_root.linear_velocity.x = 0
	if set_y_zero:
		_root.linear_velocity.y = 0

func _get_input_velocity(velocity: Vector2, delta: float, move_left: bool, move_right: bool, move_up: bool, move_down: bool) -> Vector2:

	if move_left and not move_right:
		if velocity.x > -max_speed:
			velocity.x -= acceleration * delta
	elif move_right and not move_left:
		if velocity.x < max_speed:
			velocity.x += acceleration * delta
	else:
		var xv := absf(velocity.x)
		xv -= deceleration * delta
		if xv < 0:
			xv = 0
		velocity.x = signf(velocity.x) * xv

	# up down
	if move_up and not move_down:
		if velocity.y > -max_speed:
			velocity.y -= acceleration * delta
	elif move_down and not move_up:
		if velocity.y < max_speed:
			velocity.y += acceleration * delta
	else:
		var yv := absf(velocity.y)
		yv -= deceleration * delta
		if yv < 0:
			yv = 0
		velocity.y = signf(velocity.y) * yv

	return velocity



#endregion
