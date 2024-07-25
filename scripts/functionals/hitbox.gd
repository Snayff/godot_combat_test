@icon("res://assets/node_icons/hit.png")
## area that deals damage to a Hurtbox.
class_name HitboxComponent
extends Area2D


# Create a signal for when the hitbox hits a hurtbox
signal hit_hurtbox(hurtbox: HurtboxComponent)


func _ready():
	# Connect on area entered to our hurtbox entered function
	area_entered.connect(_on_hurtbox_entered)

func _on_hurtbox_entered(hurtbox: HurtboxComponent):
	# Make sure the area we are overlapping is a hurtbox
	if not hurtbox is HurtboxComponent: return

	# Make sure the hurtbox isn't invincible
	if hurtbox.is_invincible: return

	# Signal out that we hit a hurtbox (this is useful for destroying projectiles when they hit something)
	hit_hurtbox.emit(hurtbox)

	# Have the hurtbox signal out that it was hit
	hurtbox.hurt.emit(self)
