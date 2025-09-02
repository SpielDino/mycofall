extends Node3D

signal track_player
signal stop_track_player
signal search_player
signal stop_seach_player

@export_group("DetectionBehaviour")
@export var hearing_range: float = 40
@export var vision_range: float = 40

@export_group("Ally communication")
@export var last_known_location_duration: float = 5
  
var player: Node3D
var player_is_in_hearing_area: bool = false
var player_is_in_vision_area: bool = false
var isTracking: bool = false
var knowns_players_current_location: bool = false
var allies: Array = []
var detected_player: bool = false

#Last known location tracker
var player_location_known_from_ally: bool = false
var tracking_duration: float = 0
var last_known_location: Vector3

var enemy

@onready var hearing_node = $HearingArea
@onready var vision_node = $VisionArea

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.getPlayer()
	
	hearing_node.scale = Vector3(hearing_range, hearing_range, hearing_range)
	vision_node.scale = Vector3(vision_range, vision_range, vision_range)

func _physics_process(delta):
	if detect() and !detected_player:
		track_player.emit()
		detected_player = true
	elif !detect() and detected_player:
		stop_track_player.emit()
		detected_player = false

func search(delta):
	if player_location_known_from_ally:
		if tracking_duration == last_known_location_duration:
			search_player.emit()
		tracking_duration -= delta
		if tracking_duration <= 0:
			stop_seach_player.emit()

func detect():
	if !isTracking:
		return false
	if player_is_in_hearing_area:
		if !player.isSneaking:
			ping_allies()
			return true
	if player_is_in_vision_area:
		if enemy.detect_player_raycast():
			ping_allies()
			return true
	return false

func get_pinged(player_location):
	player_location_known_from_ally = true
	last_known_location = player_location
	tracking_duration = last_known_location_duration

func ping_allies():
	for ally in allies:
		ally.get_pinged(player.get_child(0).global_position)

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
