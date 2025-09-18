extends Node3D

@export_group("DetectionBehaviour")
@export var hearing_range: float = 40
@export var vision_range: float = 40
@export var isTracking: bool = true
@export var always_tracking: bool = false

@export_group("Ally communication")
@export var last_known_location_duration: float = 5

var enemy

var player: Node3D
var player_is_in_hearing_area: bool = false
var player_is_in_vision_area: bool = false
var knowns_players_current_location: bool = false
var allies: Array = []
var detected_player: bool = false
#Last known location tracker
var player_location_known_from_ally: bool = false
var tracking_duration: float = 0
var last_known_location: Vector3

@onready var hearing_node = $HearingArea
@onready var vision_node = $VisionArea

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()
	
	hearing_node.scale = Vector3(hearing_range, hearing_range, hearing_range)
	vision_node.scale = Vector3(vision_range, vision_range, vision_range)

func _physics_process(delta):
	if detect() or always_tracking:
		if enemy.state != enemy.States.ATTACK_TYPE_1 and enemy.state != enemy.States.ATTACK_TYPE_2:
			enemy.state = enemy.States.MOVING 
	elif !detect():
		if enemy.state == enemy.States.MOVING:
			enemy.state = enemy.States.NONE

func search(delta):
	if player_location_known_from_ally:
		if tracking_duration == last_known_location_duration:
			enemy.state = enemy.States.SEARCHING 
		tracking_duration -= delta
		if tracking_duration <= 0:
			enemy.state = enemy.States.NONE 

func detect():
	if !isTracking:
		detected_player = false
		return false
	if player_is_in_hearing_area:
		if !player.is_sneaking or detected_player:
			ping_allies()
			detected_player = true
			return true
	if player_is_in_vision_area:
		if enemy.detect_player_raycast():
			ping_allies()
			detected_player = true
			return true
	detected_player = false
	return false

func get_pinged():
	player_location_known_from_ally = true
	last_known_location = player.get_child(0).global_position
	tracking_duration = last_known_location_duration

func ping_allies():
	for ally in allies:
		ally.get_pinged()

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

func _on_notify_area_entered(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		allies.append(area.get_parent())

func _on_notify_area_exited(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		allies.erase(area.get_parent())
