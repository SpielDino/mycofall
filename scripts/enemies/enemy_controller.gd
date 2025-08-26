extends CharacterBody3D

enum States {NONE, IDLE, ATTACK_TYPE_1, ATTACK_TYPE_2, MOVING, SEARCHING, PATROLLING}

@export_category("Stats")
@export_subgroup("Enemy Stats")
@export var health: int = 300

@export_subgroup("Attack Stats")
@export var attackDamage: int = 10
@export var attackSpeed: float = 1
@export var attackDelay: float = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var player
var state = States.NONE
var deathTimer: float = 10

@onready var animation_player = $Model/AnimationPlayer

func _ready():
	set_connections()
	player = GlobalPlayer.getPlayer()

func _physics_process(delta):
	if health <= 0:
		die()

func activate_movement():
	if state != States.ATTACK_TYPE_1 or state != States.ATTACK_TYPE_2:
		state = States.MOVING 

func deactivate_movement():
	if state == States.MOVING:
		state = States.NONE

func set_connections():
	var children = get_children()
	if 1: #TODO: Check if enemy has specific tpye of child #Detection Child
		get_child(0).track_player.connect(activate_movement)
		get_child(0).stop_track_player.connect(deactivate_movement)

func die():
	queue_free()
	
func detect_player_raycast():
	var space_state = get_world_3d().direct_space_state
	var origin = global_position
	var end = player.get_child(0).global_position 
	var query = PhysicsRayQueryParameters3D.create(origin, end, 3, [self])

	var result = space_state.intersect_ray(query)
	#Might need some adustment, crashes if the raycast never hits a collider
	if result != null:
		var collider = result.collider
		if collider is Node:
			if collider.is_in_group("Player"):
				return true
	return false

func takeDamage(damage: int, type: String):
	health -= damage
	$AudioStreamPlayer3D.play()
	if health <= 0 and deathTimer == 10:
		deathTimer = 8
		if type == "bow":
			PlayerActionTracker.bowKills += 1
		if type == "staff":
			PlayerActionTracker.staffKills += 1
		if type == "sword":
			PlayerActionTracker.meleeKills += 1
	else:
		pass
		#TODO send signal to detection component
