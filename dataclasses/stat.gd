## a numerical statistic, with helper functionality for handling modifications
##
## for modifiers, additions are handled before multiplications
@icon("res://scripts/dataclasses/stat.png")
class_name StatData
extends Resource


#region SIGNALS
signal base_value_changed
signal modifier_added
signal modifier_removed
#endregion


#region ON READY

#endregion


#region EXPORTS
# @export_group("Component Links")
# @export var
@export_group("Details")
@export var type: Constants.STAT_TYPE
@export var base_value: float:
	set(value):
		base_value = value
		base_value_changed.emit()
#endregion


#region VARS
var _modifiers: Array[StatModData]
## base_value modified by all _modifiers
var _modified_value: float
## the current value of the stat
##
## protected value. to set the value use [base_value] and adding or removing mods
var value: float:
	set(value_):
		push_error("StatData: Can't set directly.")
	get:
		if _is_dirty:
			_recalculate()
		return _modified_value
## if the value has changed since last recalculated
var _is_dirty: bool = true
#endregion


#region FUNCS
func _init(type_: Constants.STAT_TYPE = Constants.STAT_TYPE.strength, base_value_: float = 0) -> void:
	resource_local_to_scene = true
	type = type_
	base_value = base_value_

## recalculate the current value
func _recalculate() -> void:
	_modified_value = base_value
	var multiplier: float = 1
	for mod in _modifiers:
		if mod.type == Constants.MATH_MOD_TYPE.add:
			_modified_value += mod.amount

		elif  mod.type == Constants.MATH_MOD_TYPE.multiply:
			multiplier *= mod.amount

		else:
			push_warning("StatData: unable to handle mod type of ", mod.type, ".")

	_modified_value *= multiplier
	_is_dirty = false

## add a new modifier to the stat
func add_mod(mod: StatModData) -> void:
	# keep for debugging
	# print(Utility.get_enum_name(Constants.STAT_TYPE, type), "'s pre mod value: ", value)

	_modifiers.append(mod)
	modifier_added.emit()
	_is_dirty = true

	# keep for debugging
	#print(Utility.get_enum_name(Constants.STAT_TYPE, type), "'s post mod value: ", value)

## remove an existing modifier from the stat
func remove_mod(mod: StatModData) -> void:
	_modifiers.erase(mod)
	modifier_removed.emit()
	_is_dirty = true

## remove all modifiers from the stat
func remove_all_mods() -> void:
	_modifiers = []
	_is_dirty = true

#endregion
