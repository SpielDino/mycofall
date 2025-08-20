extends Node3D
@export_group("Movement Stats")
@export var speed: int = 5
@export var acceleration: int = 5

@export_group("Movement Behaviour")
@export_enum("stand still", "move towards player", "keep set distance from player") var movement_type: String = "stand still"
@export var keep_distance: float = 5
@export var has_patrol_route: bool = false
@export var patrol_locations: Array[Node3D]


var enemy
var player
var is_moving = false
var move_time: float = 0
var move_delay: float = 0.2
var patrol_counter: float = 0

@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.getPlayer()

func _physics_process(delta):
	if (enemy.state == enemy.States.None or enemy.state == enemy.States.PATROLLING) and has_patrol_route:
		patrol_between_set_locations()
	enemy.state = enemy.States.PATROLLING
	enemy.move_and_slide()

func move_towards_player(delta):
	var direction = Vector3()
	nav.target_position = player.get_child(0).global_position
	
	direction = (nav.get_next_path_position() - global_position).normalized()
	enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)

func keep_set_distance_from_player(delta):
	var distance = global_position.distance_to(player.get_child(0).global_position)
	is_moving = false
	move_time += delta
	if move_delay > 0:
		move_delay -= delta
	if distance >= keep_distance or !enemy.detect_player_raycast():
		var direction = Vector3()
		nav.target_position = player.get_child(0).global_position
		direction = (nav.get_next_path_position() - global_position).normalized()
		enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)
		is_moving = true
		move_delay = 0.2
		move_time = 0
	else:
		enemy.velocity = Vector3(0, enemy.velocity.y, 0)

func patrol_between_set_locations():
	null

func stand_still():
	null
