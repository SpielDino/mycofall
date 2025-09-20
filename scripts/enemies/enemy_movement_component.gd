extends Node3D
@export_group("Movement Stats")
@export var speed: int = 5
@export var acceleration: int = 5

@export_group("Movement Behaviour")
@export_enum("stand still", "move towards player", "keep set distance from player", "move between points") var movement_type: String = "stand still"
@export var keep_distance: float = 5
@export var has_patrol_route: bool = false

@export_group("Animation Variables")
@export var walking_name: String = "Walking"
@export var walking_animation_speed: float = 1
@export var idle_name: String = "Idle"
@export var warmup_animation_name: String = "Idle"
@export var warmup_animation_time: float = 0

var enemy
var player

var is_moving = false
var move_time: float = 0
var move_delay: float = 0.2 
var warmup_timer: float = warmup_animation_time
var move_counter: int = 0
var next_patrol_point: Vector3
var reached_patrol_target: bool

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var patrol_locations: Array[Node] = $PatroleMarker.get_children()
@onready var move_locations: Array[Node] = $MoveMarker.get_children()

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()

func _physics_process(delta):
	if !enemy.died:
		play_movement_animations()
		decide_movement_type(delta)
		apply_gravity(delta)

func move_towards_location(delta, location):
	var direction = Vector3()
	if type_string(typeof(location)) == "Vector3":
		nav.target_position = location
	else:
		nav.target_position = location.global_position
	direction = (nav.get_next_path_position() - global_position).normalized()
	enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)
	enemy.rotate_to_target(location)

func keep_set_distance_from_player(delta):
	var distance = global_position.distance_to(player.get_child(0).global_position)
	if distance >= keep_distance or !enemy.detect_player_raycast():
		var direction = Vector3()
		nav.target_position = player.get_child(0).global_position
		direction = (nav.get_next_path_position() - global_position).normalized()
		enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)
	else:
		enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	enemy.rotate_to_target(player.get_child(0))

func move_between_set_locations(delta, move_points):
	if global_position.distance_to(move_points[move_counter].global_position) <= 1:
		if move_counter+1 < move_points.size():
			move_counter += 1;
		else:
			move_counter = 0
	var direction = Vector3()
	nav.target_position = move_points[move_counter].global_position
	print(move_points[move_counter].global_position)
	direction = (nav.get_next_path_position() - global_position).normalized()
	enemy.rotate_to_target(move_points[move_counter])
	enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)
	
func stand_still():
	enemy.rotate_to_target(player.get_child(0))
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)

func play_movement_animations():
	if enemy.state == enemy.States.IDLE or (enemy.state != enemy.States.ATTACK_TYPE_1 and movement_type == "stand still"):
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play(idle_name)
	if (enemy.state == enemy.States.PATROLLING or enemy.state == enemy.States.SEARCHING or enemy.state == enemy.States.MOVING) and movement_type != "stand still":
		if warmup_timer <= 0:
			enemy.animation_player.speed_scale = walking_animation_speed
			enemy.animation_player.play(walking_name)
		else: 
			enemy.animation_player.speed_scale = 1
			enemy.animation_player.play(warmup_animation_name)

func decide_movement_type(delta):
	if (enemy.state == enemy.States.NONE or enemy.state == enemy.States.PATROLLING) and has_patrol_route:
		move_between_set_locations(delta, patrol_locations)
		enemy.state = enemy.States.PATROLLING
		warmup_timer = warmup_animation_time
		searching(delta)
		enemy.move_and_slide()
	if (enemy.state == enemy.States.NONE or enemy.state == enemy.States.IDLE) and !has_patrol_route:
		enemy.state = enemy.States.IDLE
		warmup_timer = warmup_animation_time
		searching(delta)
	if enemy.state == enemy.States.MOVING:
		if warmup_timer <= 0:
			match movement_type:
				"stand still":
					stand_still()
				"move towards player":
					move_towards_location(delta, player.get_child(0))
				"keep set distance from player":
					keep_set_distance_from_player(delta)
				"move between points":
					move_between_set_locations(delta, move_locations)
			enemy.move_and_slide()
		else:
			warmup_timer -= delta

func searching(delta):
	var detection_component = enemy.get_child(0)
	if detection_component.player_location_known_from_ally:
		if detection_component.tracking_duration <= 0:
			enemy.state = enemy.States.NONE
			detection_component.player_location_known_from_ally = false
			#TODO maybe let them walk back to from where they came from
		else: 
			detection_component.tracking_duration -= delta
			enemy.state = enemy.States.SEARCHING
			move_towards_location(delta, detection_component.last_known_location)
			if global_position.distance_to(detection_component.last_known_location) <= 0.5:
				enemy.state = enemy.States.NONE
				detection_component.tracking_duration = 0
				detection_component.player_location_known_from_ally = false
				#TODO maybe add the enemy randomly looking around in different directions

func apply_gravity(delta):
	enemy.velocity.y += -enemy.gravity * delta
