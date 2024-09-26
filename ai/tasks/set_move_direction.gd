## set a direction to move in
## [code]FAILURE[/code] if agent doesnt have [PhysicsMovementComponent].
@tool
extends BTAction

## blackboard var for direction
@export var target_direction_var: StringName = &"target_direction"
## blackboard var for direction duration
@export var direction_duration_var: StringName = &"direction_duration"
## how long to move in direction
@export var move_in_direction_duration: float = 1.0

func _generate_name() -> String:
	return "SetMoveDirection: tell agent to move in %s for %ss ➜ %s" % [
		LimboUtility.decorate_var(target_direction_var),
		move_in_direction_duration,
		LimboUtility.decorate_var(direction_duration_var),
	]

func _tick(_delta: float) -> Status:
	if agent is not Actor:
		return FAILURE

	var target_direction: Vector2 = blackboard.get_var(target_direction_var, null)
	if target_direction is not Vector2:
		return FAILURE

	agent.physics_movement.set_target_direction(target_direction, move_in_direction_duration)
	blackboard.set_var(direction_duration_var, move_in_direction_duration)

	return SUCCESS
