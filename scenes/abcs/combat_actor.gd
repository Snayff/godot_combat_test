## entity that can move and fight in combat
@icon("res://assets/node_icons/actor.png")
class_name CombatActor
extends RigidBody2D

#region SIGNALS
signal target_changed(actor: CombatActor)  ## changed target to new combat_actor
signal died  ## actor has died
#endregion


#region ON READY
#FIXME: can we get rid of some of these? shouldnt we only need them for things we use in this script, rather than as an interface for other nodes, who
#  could use get_node()?
@onready var _on_hit_flash: FlashComponent = %OnHitFlash
@onready var reusable_spawner: SpawnerComponent = %ReusableSpawner  ## component for spawning runtime-defined Nodes on the actor
@onready var allegiance: Allegiance = %Allegiance
@onready var _damage_numbers: PopUpNumbers = %DamageNumbers
@onready var _death_trigger: DeathTrigger = %DeathTrigger
@onready var _physics_movement: PhysicsMovementComponent = %PhysicsMovement
@onready var boons_banes: BoonsBanesContainerComponent = %BoonsBanesContainer
@onready var _supply_container: SupplyContainerComponent = %SupplyContainer
@onready var _combat_active_container: CombatActiveContainerComponent = %CombatActiveContainer

#endregion


#region EXPORTS
@export_group("Details")
@export var _is_player: bool = false  ## if the actor is player controlled
@export_group("Physics")
@export var _linear_damp: float = 5  ## set here, rather than built-in, due to editor issue
@export var _mass: float = 100  ## set here, rather than built-in, due to editor issue
#endregion


#region VARS
var _num_ready_actives: int = 0
var _global_cast_cd: float = 0.5  ## min time to wait between combat active casts
var _global_cast_cd_counter: float = 0  ## counter to track time since last cast
var _target: CombatActor:
	set(value):
		_target = value
		target_changed.emit(_target)
#endregion


#region FUNCS
func _ready() -> void:
	# NOTE: for some reason these arent being applied via the editor, but applying via code works
	linear_damp = _linear_damp
	mass = _mass
	lock_rotation = true

	update_collisions()

	if _supply_container is SupplyContainerComponent:
		var health = _supply_container.get_supply(Constants.SUPPLY_TYPE.health)
		health.value_decreased.connect(_on_hit_flash.activate.unbind(1))  # activate flash on hit
		health.emptied.connect(func(): died.emit())  # inform of death when empty
		health.value_decreased.connect(_damage_numbers.display_number)

	if _physics_movement is PhysicsMovementComponent:
		_physics_movement.is_attached_to_player = _is_player

	_death_trigger.died.connect(func(): died.emit())

	_combat_active_container.has_ready_active.connect(func(): _num_ready_actives += 1)
	_combat_active_container.new_active_selected.connect(func(): _target = _combat_active_container.selected_active.target_actor)

func _process(delta: float) -> void:
	_global_cast_cd_counter -= delta

	_update_non_player_auto_casting()

## handle auto casting for non-player combat actors
func _update_non_player_auto_casting() -> void:
	# NOTE: should this be in an AI node?
	if not _is_player:
		if _num_ready_actives > 0:
			if _global_cast_cd_counter <= 0:
				if _combat_active_container.cast_random_ready_active():
					_num_ready_actives -= 1
					_global_cast_cd_counter = _global_cast_cd

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _physics_movement is PhysicsMovementComponent:
		_physics_movement.calc_movement(state)

## updates all collisions to reflect current _target, team etc.
func update_collisions() -> void:
	Utility.update_body_collisions(self, allegiance.team, Constants.TARGET_OPTION.other, _target)
#endregion
