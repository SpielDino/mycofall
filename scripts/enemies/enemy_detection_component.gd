extends Node3D

@export_group("Detection Behaviour")
@export var is_tracking: bool = true
@export var always_tracking: bool = false
@export var player_memory_duration: float = 5

@export_group("Ally communication")
@export var last_known_location_duration: float = 5

var enemy

var player: Node3D
var player_is_in_hearing_area: bool = false
var player_is_in_vision_area: bool = false
var knowns_players_current_location: bool = false
var allies: Array = []
var detected_player: bool = false
var last_saw_player: float = 5
#Last known location tracker
var player_location_known_from_ally: bool = false
var tracking_duration: float = 0
var last_known_location: Vector3

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()

func _physics_process(delta):
	if detect() or always_tracking:
		if enemy.state != enemy.States.ATTACK_TYPE_1 and enemy.state != enemy.States.ATTACK_TYPE_2:
			enemy.state = enemy.States.MOVING 
	elif !detect():
		if enemy.state == enemy.States.MOVING:
			enemy.state = enemy.States.NONE
	if last_saw_player < player_memory_duration:
		last_saw_player += delta

func search(delta):
	if player_location_known_from_ally:
		if tracking_duration == last_known_location_duration:
			enemy.state = enemy.States.SEARCHING 
		tracking_duration -= delta
		if tracking_duration <= 0:
			enemy.state = enemy.States.NONE 

func remembers_player():
	if player_memory_duration > last_saw_player:
		return true
	else:
		return false

func detect():
	if always_tracking:
		detected_player = true
		last_saw_player = 0
		return true
	if !is_tracking:
		detected_player = false
		return false
	if remembers_player():
		detected_player = true
		return true
	if player_is_in_hearing_area:
		if !player.is_sneaking:
			ping_allies()
			detected_player = true
			last_saw_player = 0
			return true
	if player_is_in_vision_area:
		if enemy.detect_player_raycast():
			ping_allies()
			detected_player = true
			last_saw_player = 0
			return true
	detected_player = false
	return false

func get_pinged():
	player_location_known_from_ally = true
	last_known_location = player.get_child(0).global_position
	tracking_duration = last_known_location_duration

func ping_allies():
	for ally in allies:
		ally.get_child(0).get_pinged()

func activate_tracking():
	always_tracking = true

func _on_hearing_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_is_in_hearing_area = true

func _on_hearing_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_is_in_hearing_area = false

func _on_vision_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_is_in_vision_area = true

func _on_vision_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_is_in_vision_area = false

func _on_notify_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		allies.append(body)

func _on_notify_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		allies.erase(body)
