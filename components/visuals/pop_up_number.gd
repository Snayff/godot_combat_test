## pop up numbers over _root entity, a la damage numbers.
@icon("res://components/visuals/pop_up_number.png")
class_name PopUpNumbers
extends Marker2D


#region SIGNALS

#endregion


#region ON READY

#endregion


#region EXPORTS
@export_group("Component Links")
@export var _root: Node2D  ## @REQUIRED.
@export_group("Colours")
@export var _font_colour: Color = Color.WHITE
@export var _font_alt_colour: Color = Color.FIREBRICK
@export_group("Font")
@export var _font_size: int = 16
@export var _font: FontFile = FontFile.new()
@export_group("Outline")
@export var _outline_colour: Color = Color.BLACK
@export var _outline_size: int = 1
@export_group("Other")
@export var _duration: float = 0.3
#endregion


#region VARS


#endregion


#region FUNCS
## show the pop up number and related effects
func display_number(value: float, use_alt_settings: bool = false) -> void:
	var _label: Label = Label.new()
	add_child(_label)
	_label.global_position = global_position
	_label.text = str(value)
	_label.z_index = _root.z_index + 1  # NOTE: tut says set to 5

	_label.label_settings = LabelSettings.new()
	if use_alt_settings:
		_label.label_settings.font_color = _font_alt_colour
	else:
		_label.label_settings.font_color = _font_colour
	_label.label_settings.font_size = _font_size
	_label.label_settings.outline_color = _outline_colour
	_label.label_settings.outline_size = _outline_size
	if _font is FontFile:
		_label.label_settings.font = _font

	# when size updated, offest to centre
	await  _label.resized
	_label.pivot_offset = Vector2(_label.size / 2)  # FIXME: this doesnt seem to be working as still seems offset to the right

	# tween position up and down
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	# TODO: tween in a random direction, up and away
	var rand_offset_x: float = randf_range(-15, 15)

	# move left or right
	tween.tween_property(_label, "position:x", _label.position.x - rand_offset_x, _duration / 2).set_ease(Tween.EASE_OUT)

	# move up then back down
	var rand_offset_y: float = randf_range(-3, 3)
	tween.tween_property(_label, "position:y", _label.position.y - (18 + rand_offset_y), _duration / 2).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		_label,
		"position:y",
		_label.position.y, _duration / 2
		).set_ease(Tween.EASE_IN).set_delay(_duration / 2)

	# shrink when falling
	tween.tween_property(_label, "scale", Vector2.ZERO, _duration / 2).set_ease(Tween.EASE_OUT).set_delay(_duration / 2)

	# clear when tween finished
	await  tween.finished
	_label.queue_free()




#endregion
