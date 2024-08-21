## misc, helpful functions
extends Node


#region VARS

#endregion


#region FUNCS
## set the collision layers and masks, based on team and targeting, to the relevant "_body" collision layers.
func update_body_collisions(node: CollisionObject2D, team: Constants.TEAM, target_option: Constants.TARGET_OPTION, target_actor: CombatActor = null) -> void:
	_update_collisions(node, team, target_option, Constants.COLLISION_LAYER.team1_body, Constants.COLLISION_LAYER.team2_body, target_actor)

## set the collision layers and masks, based on team and targeting, to the relevant "_hitbox_hurtbox" collision layers.
func update_hitbox_hurtbox_collision(node: CollisionObject2D, team: Constants.TEAM, target_option: Constants.TARGET_OPTION, target_actor: CombatActor = null) -> void:
	_update_collisions(node, team, target_option, Constants.COLLISION_LAYER.team1_hitbox_hurtbox, Constants.COLLISION_LAYER.team2_hitbox_hurtbox, target_actor)

## unified func to update collisions
func _update_collisions(
	node: CollisionObject2D,
	team: Constants.TEAM,
	target_option: Constants.TARGET_OPTION,
	team1: Constants.COLLISION_LAYER,
	team2: Constants.COLLISION_LAYER,
	target_actor: CombatActor = null
	) -> void:
	if not(node is CollisionObject2D and team is Constants.TEAM and target_option is Constants.TARGET_OPTION):
		push_warning("Utility: args of incorrect type.")
		return

	# clear existing - 1-32 are the possible layers/masks
	for i in range(1, 32):
		node.set_collision_layer_value(i, false)
		node.set_collision_mask_value(i, false)

	# LAYERS
	node.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], team == Constants.TEAM.team1)
	node.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], team == Constants.TEAM.team2)

	# MASKS
	# only same team
	if target_option in [Constants.TARGET_OPTION.self_, Constants.TARGET_OPTION.ally]:
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], team == Constants.TEAM.team1)
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], team == Constants.TEAM.team2)

	# only other team
	elif target_option in [Constants.TARGET_OPTION.enemy]:
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], team != Constants.TEAM.team1)
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], team != Constants.TEAM.team2)

	# any team
	elif target_option in [Constants.TARGET_OPTION.anyone, Constants.TARGET_OPTION.other]:
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], true)
		node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], true)

	# only team of target
	elif target_option in [Constants.TARGET_OPTION.target]:
		if target_actor is CombatActor:
			var target_allegiance: Allegiance = target_actor.get_node_or_null("Allegiance")
			if target_allegiance is Allegiance:
				var target_team: Constants.TEAM = target_allegiance.team
				node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], target_team == Constants.TEAM.team1)
				node.set_collision_mask_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], target_team == Constants.TEAM.team2)
				node.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team1_body], target_team == Constants.TEAM.team1)
				node.set_collision_layer_value(Constants.COLLISION_LAYER_MAP[Constants.COLLISION_LAYER.team2_body], target_team == Constants.TEAM.team2)

## check target is of type expected, as per [TARGET_OPTION]
##
## Only check against the items that identify self, not self, or target, as the [TEAM] element should be handled by collision layer/mask.
func target_is_valid(target_option: Constants.TARGET_OPTION, originator: Node2D, target: Node2D, target_actor: CombatActor = null) -> bool:
	if target_option == Constants.TARGET_OPTION.self_:
		if originator == target:
			return true
		else:
			return false

	elif target_option == Constants.TARGET_OPTION.other:
		if originator != target:
			return true
		else:
			return false

	elif target_option == Constants.TARGET_OPTION.target:
		if target_actor == target:
			return true
		else:
			return false

	## ignore other target checks as already filtered by collision layers
	return true



#endregion
