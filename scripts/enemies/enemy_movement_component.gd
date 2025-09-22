extends Node3D
@export_group("Movement Stats")
@export var speed: int = 5
@export var acceleration: int = 5

@export_group("Movement Behaviour")
@export_enum("stand still", "move towards player", "move between points") var movement_type: String = "stand still"
@export var keep_distance: float = 5
@export var has_patrol_route: bool = false

@export_group("Animation Variables")
@export var walking_name: String = "Walking"
@export var attack_walking_name: String = "Walking"
@export var attack_walking_speedscale: float = 1
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
var start_idle_point: Vector3
var return_to_idle_point: bool = true

var patrol_positions: Array[Vector3]
var move_positions: Array[Vector3]

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var patrol_locations = $PatroleMarker
@onready var move_locations = $MoveMarker

@onready var walking_sounds: AudioStreamPlayer3D = $WalkingSounds
@onready var running_sounds: AudioStreamPlayer3D = $RunningSounds

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()
	get_marker_positions(patrol_locations, patrol_positions)
	get_marker_positions(move_locations, move_positions)
	start_idle_point = global_position

func _physics_process(delta):
	if !enemy.died:
		play_movement_animations()
		decide_movement_type(delta)
		apply_gravity(delta)
		enemy.move_and_slide()

func get_marker_positions(locations, positions):
	var array: Array[Node] = locations.get_children()
	if array.size() > 0:
		for location in array:
			positions.append(location.global_position)
	locations.queue_free()

func move_towards_location(delta, location, move_speed):
	var direction = Vector3()
	if type_string(typeof(location)) == "Vector3":
		nav.target_position = location
	else:
		nav.target_position = location.global_position
	direction = (nav.get_next_path_position() - global_position).normalized()
	enemy.velocity = enemy.velocity.lerp(direction * move_speed, acceleration * delta)
	enemy.rotate_to_target(location)

func move_between_set_locations(delta, move_points):
	if move_counter >= move_points.size():
		move_counter = 0
	if global_position.distance_to(move_points[move_counter]) <= 1:
		if move_counter + 1 < move_points.size():
			move_counter += 1;
		else:
			move_counter = 0
	var direction = Vector3()
	nav.target_position = move_points[move_counter]
	direction = (nav.get_next_path_position() - global_position).normalized()
	if enemy.slow_rotate_to_target(nav.get_next_path_position()):
		enemy.velocity = enemy.velocity.lerp(direction * speed, acceleration * delta)
	else:
		enemy.velocity = enemy.velocity.lerp(Vector3(0,enemy.velocity.y,0), acceleration * delta * 10)

func stand_still():
	enemy.rotate_to_target(player.get_child(0))
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)

func play_movement_animations():
	var animation_name = walking_name
	var sound_name = walking_sounds
	if enemy.state == enemy.States.IDLE or (enemy.state != enemy.States.ATTACK_TYPE_1 and movement_type == "stand still"):
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play(idle_name)
	if (enemy.state == enemy.States.PATROLLING or enemy.state == enemy.States.SEARCHING or enemy.state == enemy.States.MOVING or enemy.state == enemy.States.RETURNING) and movement_type != "stand still":
		if enemy.state == enemy.States.MOVING:
			animation_name = attack_walking_name
			sound_name = running_sounds
		if warmup_timer <= 0:
			enemy.animation_player.speed_scale = walking_animation_speed
			enemy.animation_player.play(animation_name)
			if !sound_name.playing:
				sound_name.play()
		else: 
			enemy.animation_player.speed_scale = 1
			enemy.animation_player.play(warmup_animation_name)
	if enemy.state == enemy.States.ATTACK_TYPE_1 or movement_type == "stand still":
		if sound_name.playing or running_sounds.playing or walking_sounds.playing:
			sound_name.stop()
			running_sounds.stop()
			walking_sounds.stop()

func decide_movement_type(delta):
	searching(delta)
	if (enemy.state == enemy.States.NONE or enemy.state == enemy.States.PATROLLING) and has_patrol_route:
		move_between_set_locations(delta, patrol_positions)
		enemy.state = enemy.States.PATROLLING
		warmup_timer = warmup_animation_time
	if (enemy.state == enemy.States.NONE or enemy.state == enemy.States.IDLE or enemy.state == enemy.States.RETURNING) and !has_patrol_route:
		if global_position.distance_to(start_idle_point) > 1 and return_to_idle_point:
			enemy.state = enemy.States.RETURNING
			move_towards_location(delta, start_idle_point, speed)
		else:
			enemy.state = enemy.States.IDLE
			warmup_timer = warmup_animation_time
			enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	if enemy.state == enemy.States.MOVING:
		if warmup_timer <= 0:
			match movement_type:
				"stand still":
					stand_still()
				"move towards player":
					move_towards_location(delta, player.get_child(0), speed * attack_walking_speedscale)
				"move between points":
					move_between_set_locations(delta, move_positions)
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
			move_towards_location(delta, detection_component.last_known_location, speed)
			if global_position.distance_to(detection_component.last_known_location) <= 0.5:
				enemy.state = enemy.States.NONE
				detection_component.tracking_duration = 0
				detection_component.player_location_known_from_ally = false
				#TODO maybe add the enemy randomly looking around in different directions

func apply_gravity(delta):
	enemy.velocity.y += -enemy.gravity * delta
