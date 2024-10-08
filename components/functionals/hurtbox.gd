@icon("res://components/functionals/hurtbox.png")
## Area where entity can be hurt.
class_name HurtboxComponent
extends Area2D


@export_group("Component Links")
@export var root: Actor  ## the actor that created the thing that used this hitbox. @REQUIRED.


var is_invincible = false:  # NOTE: probs needs moving to some central status effects
	# disable and enable collision shapes on the hurtbox when is_invincible is changed.
	set(value):
		is_invincible = value
		# Disable any collisions shapes on this hurtbox when it is invincible
		# And reenable them when it isn't invincible
		for child in get_children():
			if not child is CollisionShape2D and not child is CollisionPolygon2D: continue
			# Use call deferred to make sure this doesn't happen in the middle of the
			# physics process
			child.set_deferred("disabled", is_invincible)

func _ready() -> void:
	assert(root is Actor, "Missing `root`.")
