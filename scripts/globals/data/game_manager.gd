extends Node

signal weapons_changed
signal attacks
signal blocks
signal attack_loading_updated
signal heavy_attack

var first_weapon: bool = false
var second_weapon: bool = false
var first_weapon_name: String = ""
var second_weapon_name: String = ""
var bow_attack_timer: float
var attack_loading_value: float = bow_attack_timer
var is_attacking: bool = false
var is_blocking: bool = false
var having_i_frames: bool = false
var is_dodging: bool = false
var is_sneaking: bool = false
var controller_input_device: bool = false
var first_weapon_upgrade_level: int = 0
var second_weapon_upgrade_level: int = 0
var is_sword_hit: bool = false
var is_heavy_attacking: bool = false

func get_first_weapon():
	return first_weapon

func set_first_weapon(check: bool):
	first_weapon = check

func get_second_weapon():
	return second_weapon

func set_second_weapon(check: bool):
	second_weapon = check

func get_first_weapon_name():
	return first_weapon_name
	
func set_first_weapon_name(check: String):
	first_weapon_name = check

func get_second_weapon_name():
	return second_weapon_name
	
func set_second_weapon_name(check: String):
	second_weapon_name = check
	
func get_first_weapon_upgrade_level():
	return first_weapon_upgrade_level
	
func set_first_weapon_upgrade_level(check: int):
	first_weapon_upgrade_level = check
	
func get_second_weapon_upgrade_level():
	return second_weapon_upgrade_level

func set_second_weapon_upgrade_level(check: int):
	second_weapon_upgrade_level = check
	
func get_bow_attack_timer():
	return bow_attack_timer
	
func set_bow_attack_timer(check):
	bow_attack_timer = round(check*100)/100
	set_attack_loading_value(bow_attack_timer)

func get_attack_loading_value():
	return attack_loading_value
	
func set_attack_loading_value(val):
	attack_loading_value = val
	attack_loading_updated.emit()
	
func get_is_attacking():
	return is_attacking

func set_is_attacking(check):
	is_attacking = check
	GameManager.attacks.emit()
	
func get_is_sword_hit():
	return is_sword_hit

func set_is_sword_hit(check):
	is_sword_hit = check
	
func get_is_heavy_attacking():
	return is_heavy_attacking

func set_is_heavy_attacking(check):
	is_heavy_attacking = check
	heavy_attack.emit()

func get_is_blocking():
	return is_blocking

func set_is_blocking(check):
	is_blocking = check
	GameManager.blocks.emit()
	
func get_having_i_frames():
	return having_i_frames

func set_having_i_frames(check):
	having_i_frames = check
	
func get_is_dodging():
	return is_dodging

func set_is_dodging(check):
	is_dodging = check
	
func get_is_sneaking():
	return is_sneaking

func set_is_sneaking(check):
	is_sneaking = check
	
func get_controller_input_device():
	return controller_input_device
	
func set_controller_input_device(check):
	controller_input_device = check

func weapons_updated():
	weapons_changed.emit()

func get_child_by_name(parent, check_name: String):
	for child in parent.get_children():
		if child.name == check_name:
			return child
			
func reset_child_to_root(parent, child):
		var pos = child.global_position
		parent.remove_child(child)
		get_tree().current_scene.add_child(child)
		child.global_position = pos

func get_mouse_ground_position_fixed(object) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var ground_y = object.global_position.y
	
	if direction.y != 0:
		var t = (ground_y - origin.y) / direction.y
		var world_pos = origin + direction * t
		return world_pos
	
	return object.global_position
