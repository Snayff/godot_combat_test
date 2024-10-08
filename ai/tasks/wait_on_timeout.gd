## pulls value from blackboard and counts down by delta
## returns [code]FAILURE[/code] if can't count down value or value not found
## returns [code]RUNNING[/code] while counting down
## returns [code]SUCCESS[/code] when value less <= 0
@tool
extends BTAction


@export_group("Input")
## var to look at to get the duration to wait
@export var timeout_var_name_var: StringName


var duration: float = 0.0


func _generate_name() -> String:
	return "WaitOnTimeout: wait until %s times out" % [
		LimboUtility.decorate_var(timeout_var_name_var)
	]

func _enter() -> void:
	var v = blackboard.get_var(timeout_var_name_var)
	if v is float:
		duration = v

func _tick(delta: float) -> Status:
	if duration <= 0.0:
		push_warning("Duration started at 0.0. Will never run.")
		return FAILURE

	duration -= delta

	if duration <= 0:
		return SUCCESS
	else:
		return RUNNING
