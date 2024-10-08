## an area2D that enables finding targets of a given type
@icon("res://components/functionals/target_finder.png")
class_name TargetFinder
extends Area2D


#region SIGNALS
signal new_target(target: Actor)
#endregion


#region ON READY (for direct children only)

#endregion


#region EXPORTS
# @export_group("Component Links")
# @export var
#
# @export_group("Details")
#endregion


#region VARS
var _shape: CollisionShape2D
var current_target: Actor
var _refresh_duration: float = 0.3  ## how long to wait before looking for a new target
var _refresh_counter: float = 0
# info needed from parent
var _max_range: float = 0  ## this sets the radius of the area.
var _target_option: Constants.TARGET_OPTION  ## the type of target we're looking for
var _root: Actor  ## the combat actor who owns this combat active this is attached to
var _allegiance: Allegiance  ## we take this, and not team directly, as Allegiance isnt init in parent before this is
var has_target: bool:  ## if target finder has a valid target
	set(_value):
		push_error("TargetFinder: Can't set has_target directly.")
	get:
		return current_target is Actor
var _has_run_ready: bool = false  ## if _ready() has finished
#endregion


#region FUNCS
func _ready() -> void:
	# check a shape has been added to scene
	_shape = get_node_or_null("CollisionShape2D")
	assert(_shape is CollisionShape2D, "TargetFinder: Missing `_shape`")

	_has_run_ready = true

## run setup process
func setup(root: Actor, max_range: float, target_option: Constants.TARGET_OPTION, allegiance: Allegiance) -> void:
	if not _has_run_ready:
		push_error("TargetFinder: setup() called before _ready. ")

	assert(root is Actor, "TargetFinder: Missing `root`")
	assert(max_range is float, "TargetFinder: Missing `max_range`")
	assert(target_option is Constants.TARGET_OPTION, "TargetFinder: Missing `target_option`")
	assert(allegiance is Allegiance, "TargetFinder: Missing `allegiance`")

	_root = root
	_target_option = target_option
	_allegiance = allegiance

	update_collisions()
	set_max_range(max_range)

func _process(delta: float) -> void:
	_refresh_counter -= delta
	if _refresh_counter <= 0:
		var nearest_target = get_nearest_target()
		if nearest_target != current_target:
			current_target = nearest_target
			new_target.emit(current_target)
		_refresh_counter = _refresh_duration

## update the collision shape's radius to match max_range
func _update_radius() -> void:
	_shape.shape.radius = _max_range

## update the body collision layers/masks
func update_collisions() -> void:
	if _allegiance is Allegiance and _target_option is Constants.TARGET_OPTION:
		Utility.update_body_collisions(self, _allegiance.team, _target_option)

## returns nearest target that is within range. If no valid targets in range, returns null.
func get_nearest_target() -> Actor:
	if is_zero_approx(_max_range):
		# check if we can use self
		if Utility.target_is_valid(_target_option, _root, _root):
			return _root

		# can't use self, so with range == 0 will never find anyone
		push_warning(
			"TargetFinder: `_max_range` == 0, will never find anyone other than self, and we're looking for ",
			Utility.get_enum_name(Constants.TARGET_OPTION, _target_option)
		)

		return

	var nearest_body: CollisionObject2D = null
	var closest_distance: float = 0
	var new_distance: float = 0
	for body in get_overlapping_bodies():
		# check target is one we care about
		if not Utility.target_is_valid(_target_option, _root, body):
			continue

		if nearest_body == null:
			nearest_body = body
			closest_distance = global_position.distance_to(body.global_position)
			continue

		new_distance = global_position.distance_to(body.global_position)
		if new_distance < closest_distance and nearest_body is Actor:
			nearest_body = body
			closest_distance = new_distance

	return nearest_body

## sets the required targeting info. also updates the collision's radius.
func set_targeting_info(max_range: float, target_option: Constants.TARGET_OPTION, allegiance: Allegiance) -> void:
	set_max_range(max_range)
	_target_option = target_option
	_allegiance = allegiance

	update_collisions()

func set_max_range(max_range: float) -> void:
	_max_range = max_range
	_update_radius()

#endregion
