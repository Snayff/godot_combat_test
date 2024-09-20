## entity that can move and fight in combat
@icon("res://combat/actors/actor.png")
class_name Actor
extends RigidBody2D

#region SIGNALS
## changed target to new combat_actor
signal new_target(actor: Actor)
## actor has died
signal died
#endregion


#region ON READY
#FIXME: can we get rid of some of these? shouldnt we only need them for things we use in this script, rather than as an interface for other nodes, who
#  could use get_node()?
@onready var _on_hit_flash: VisualEffectFlash = %OnHitFlash
## component for spawning runtime-defined Nodes on the actor
@onready var reusable_spawner: SpawnerComponent = %ReusableSpawner
@onready var allegiance: Allegiance = %Allegiance
@onready var combat_active_container: CombatActiveContainer = %CombatActiveContainer
@onready var stats_container: StatsContainer = %StatsContainer
@onready var boons_banes: BoonBaneContainer = %BoonsBanesContainer
@onready var _damage_numbers: PopUpNumbers = %DamageNumbers
@onready var _death_trigger: DeathTrigger = %DeathTrigger
@onready var _physics_movement: PhysicsMovementComponent = %PhysicsMovement
@onready var _supply_container: SupplyContainer = %SupplyContainer
@onready var _centre_pivot: Marker2D = %CentrePivot
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _tag_container: TagContainer = $TagContainer




#endregion


#region EXPORTS
@export_group("Details")
## if the actor is player controlled
@export var _is_player: bool = false
@export_group("Physics")
## how massive the actor is.
## set here, rather than built-in prop, due to editor issue
@export var _mass: float = 100
## how quickly we accelerate. uses delta, so will apply ~1/60th per frame to the velocity,
## up to max_speed. acts as interface for _physics_movement.acceleration if _physics_movement
## has completed setup.
@export var _acceleration: float:
	set(v):
		if _physics_movement is not PhysicsMovementComponent:
			return
		if not _physics_movement._has_run_setup:
			return
		_physics_movement._acceleration = v
		_acceleration = v
## how quickly we decelerate. uses delta, so will apply ~1/60th per frame to the velocity.
## applied when max_speed is hit. should be >= acceleration.
@export var _deceleration: float:
	set(v):
		if _physics_movement is not PhysicsMovementComponent:
			return
		if not _physics_movement._has_run_setup:
			return
		_physics_movement._deceleration = v
		_deceleration = v
#endregion


#region VARS
var _num_ready_actives: int = 0
var _global_cast_cd_counter: float = 0  ## counter to track time since last cast. # TODO: this needs implementing for player
var _target: Actor:
	set(value):
		_target = value
		new_target.emit(_target)
## set here, rather than built-in prop, due to editor issue
var _linear_damp: float = Constants.LINEAR_DAMP
#endregion


#region FUNCS

##########################
####### LIFECYCLE #######
########################

func _ready() -> void:
	# NOTE: for some reason these arent being applied via the editor, but applying via code works
	linear_damp = _linear_damp
	mass = _mass
	lock_rotation = true

	update_collisions()

	_death_trigger.died.connect(func(): died.emit())

	combat_active_container.has_ready_active.connect(func(): _num_ready_actives += 1)  # support knowing when to auto cast
	combat_active_container.new_active_selected.connect(func(active): _target = active.target_actor) # update target to match that of selected active
	combat_active_container.new_target.connect(func(target): _target = target)

func setup(spawn_pos: Vector2, data: DataActor) -> void:
	global_position = spawn_pos

	allegiance.team = data.team
	_sprite.sprite_frames = data.sprite_frames
	mass = data.mass
	_acceleration = data.acceleration
	_deceleration = data.deceleration

	# config supplies
	if _supply_container is SupplyContainer:
		_supply_container.create_supplies(data.supplies)
		# setup triggers and process for death on health empty
		var health: Supply = _supply_container.get_supply(Constants.SUPPLY_TYPE.health)
		health.emptied.connect(func(): died.emit())  # inform of death when empty

		# and hit effects
		health.value_decreased.connect(_on_hit_flash.activate.unbind(1))  # activate flash on hit
		health.value_decreased.connect(_damage_numbers.display_number)

		# setup triggers and process for exhaustion on stamina empty
		var stamina: Supply = _supply_container.get_supply(Constants.SUPPLY_TYPE.stamina)
		stamina.emptied.connect(_apply_exhaustion)
	else:
		push_warning("Actor: no supply container.")

	# config combat actives
	if combat_active_container is CombatActiveContainer:
		combat_active_container.create_actives(data.actives)
	else:
		push_warning("Actor: no supply container.")

	# config stats
	if stats_container is StatsContainer:
		stats_container.create_stats(data.stats)
	else:
		push_warning("Actor: no stats container.")

	# config movement - must be done after stats, as we need move speed
	if _physics_movement is PhysicsMovementComponent:
		var move_speed: float =  10.0
		if stats_container is StatsContainer:
			move_speed = stats_container.get_stat(Constants.STAT_TYPE.move_speed).value
		else:
			push_warning("Actor: actor (", name, ") didnt have stats, so used base move speed.")

		_physics_movement.setup(move_speed, data.acceleration, data.deceleration)

	# create tags
	if _tag_container is TagContainer:
		_tag_container.add_multiple_tags(data.tags)
	else:
		push_warning("Actor: no tag container.")

func _process(delta: float) -> void:
	_global_cast_cd_counter -= delta

	_update_non_player_auto_casting()

	# rotate cast position towards current target
	if combat_active_container.selected_active is CombatActive:
		if combat_active_container.selected_active.target_actor is Actor:
			_centre_pivot.look_at(combat_active_container.selected_active.target_actor.global_position)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _physics_movement is PhysicsMovementComponent:
		_physics_movement.calc_movement(state)

##########################
####### PUBLIC ##########
########################

## updates all collisions to reflect current _target, team etc.
func update_collisions() -> void:
	Utility.update_body_collisions(self, allegiance.team, Constants.TARGET_OPTION.other, _target)

func set_as_player(is_player: bool) -> void:
	_is_player = is_player

	if _physics_movement is PhysicsMovementComponent:
		_physics_movement.is_attached_to_player = _is_player


##########################
####### PRIVATE #########
########################

## add the [BoonBaneExhaustion] [ABCBoonBane]. assumed to trigger after stamina is emptied.
func _apply_exhaustion() -> void:
	var exhaustion: BoonBaneExhaustion = BoonBaneExhaustion.new(self)
	boons_banes.add_boon_bane(exhaustion)

## handle auto casting for non-player combat actors
func _update_non_player_auto_casting() -> void:
	# NOTE: should this be in an AI node?
	if not _is_player:
		if _num_ready_actives > 0:
			if _global_cast_cd_counter <= 0:
				if combat_active_container.cast_random_ready_active():
					_num_ready_actives -= 1
					_global_cast_cd_counter = Constants.GLOBAL_CAST_DELAY

#endregion
