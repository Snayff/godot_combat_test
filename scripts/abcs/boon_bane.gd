## ABC for boon_banes
#@icon("")
class_name BoonBane
extends Node


#region SIGNALS
signal terminated(boon_bane: BoonBane)
signal activated
#endregion


#region ON READY

#endregion


#region EXPORTS
# @export_group("Component Links")
# @export var
#
@export_group("Application")  # feel free to rename category
@export var trigger: Constants.TRIGGER  ## the thing that causes the boonbane to apply
@export var _duration_type: Constants.DURATION_TYPE  ## how the lifetime of the boonbane is determined
@export var _duration: float  ## how long before being removed. only relevant if duration_type == time or applications, in which case it is seconds or num applications, respectively.
@export var _interval_length: float  ## if trigger == on_interval then this dictates how long between each interval.
@export var is_unique: bool = true  ## whether multiple of the same boonbanes can be applied
#endregion


#region VARS
# internals
var _activations: int = 0  ## number of activations applied
var _duration_timer: Timer  ## only needed if duration_type is time
var _interval_timer: Timer  ## only needed if trigger is on_interval
var _source: CombatActor  ## who is the original source of the effect
# config
var host: CombatActor  ## the actor the boonbane is applied to
var _effects: Array[Effect] = []  # NOTE: should we use an EffectChain instead?  ## the effects to be activated when the trigger happens
# TODO: add an internal cooldown to allow limiting how often we trigger
#endregion


#region FUNCS
func _init(source: CombatActor) -> void:
	_source = source

func _ready() -> void:
	_configure_behaviour()  # must call first, before validity checks

	 # check required values are set
	assert(not _effects.is_empty(), "BoonBane: no effects set.")
	if trigger == Constants.TRIGGER.on_interval and _interval_length == 0:
		push_error("BoonBane: trigger is interval, but no interval_length set. Will never activate.")
	if (_duration_type == Constants.DURATION_TYPE.time or _duration_type == Constants.DURATION_TYPE.applications) and _duration == 0:
		push_error("BoonBane: duration_type is time or application, but no duration set. Will immediately terminate.")
	## NOTE: can't check the enums as they default to a meaningful value
#
	## check logic errors
	assert(_duration > _interval_length, "BoonBane: duration is less than interval_length. Will never activate.")

	_setup_timers()

## init and configure required timers
func _setup_timers() -> void:
	if _duration_type == Constants.DURATION_TYPE.time:
		_duration_timer = Timer.new()
		add_child(_duration_timer)
		_duration_timer.timeout.connect(terminate)
		_duration_timer.start(_duration)
	if trigger == Constants.TRIGGER.on_interval:
		_interval_timer = Timer.new()
		add_child(_interval_timer)
		_interval_timer.timeout.connect(activate)
		_interval_timer.start(_interval_length)

## @virtual where the effects are created and defined.
func _configure_behaviour() -> void:
	pass

## apply the effect to the target. called on trigger. must be defined in subclass and super called.
##
## defaults to the host, if not other target given
# FIXME: how is this going to work? signals are set by BoonBaneContainer and therefore wont know which target we need. How would we do an effect
# 	where the attacker gets damage returned?
func activate(target: CombatActor = host) -> void:
	activated.emit()

	for effect in _effects:
		effect.apply(target)

	# check if we have applied max number of times
	if _duration_type == Constants.DURATION_TYPE.applications:
		_activations += 1
		if _activations >= _duration:
			terminate()

## finish and clean up
func terminate() -> void:
	terminated.emit(self)

	for effect in _effects:
		effect.terminate()

	queue_free()

func _add_effect(effect: Effect) -> void:
	add_child(effect)
	_effects.append(effect)

func _remove_effect(effect: Effect) -> void:
	if effect in _effects:
		_effects[effect].terminate()
		_effects.erase(effect)

#endregion