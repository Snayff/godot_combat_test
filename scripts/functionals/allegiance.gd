@icon("res://assets/node_icons/allegiance.png")
## info regarding the team the actor is on.
## updates linked components to reflect the team.
class_name Allegiance
extends Node

@export var hurtbox: HurtboxComponent
@export var root_actor: CombatActor
@export var team: Constants.TEAM


func _ready() -> void:
	# check for mandatory properties set in editor
	assert(root_actor is CombatActor, "Misssing `root_actor`.")


	root_actor.add_to_group(str("team_", team), true)

	if hurtbox is HurtboxComponent:
		_update_hurtbox_collisions()

## update collisions of linked hurtbox based on allegiance
func _update_hurtbox_collisions() -> void:
	if team == Constants.TEAM.team1:
		hurtbox.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_hurtbox], true)
		hurtbox.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_hurtbox], false)
	elif team == Constants.TEAM.team2:
		hurtbox.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_hurtbox], false)
		hurtbox.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_hurtbox], true)
	else:
		push_error("Team selected in Allegiance not found.")
