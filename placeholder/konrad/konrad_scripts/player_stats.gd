extends Node3D

signal health_changed
signal stamina_changed
signal mana_changed

@export_category("Actions")
@export_subgroup("Walking")
@export var speed = 6.0
@export var acceleration = 20.0
##0 = No slowdown, 1 = Instant slowdown when the input ends
@export_range(0, 1) var friction: float = 0.7
#@export_range(0, 1) var sensitivity: float = 1 #Currently not used
@export_subgroup("Looking")
@export_enum("rotate based on last movement", "rotate based on second input") var rotation_type: String = "rotate based on last movement"

@export_subgroup("Dodge")
@export var stamina_cost_per_dodge: int = 50
@export var dodge_distance: float = 5.0     
@export var dodge_duration: float = 0.625
@export var no_stamina_after_dodge_time: float = 1
@export var dodge_strength_multiplier_shield: float = 0.6
@export var dodge_strength_multiplier_bow: float = 0.8
@export var dodge_strength_multiplier_staff: float = 0.7
@export_subgroup("I-Frames")
@export var i_frame_timer: float = 0.3
@export var max_i_frame_timer: float = 0.3
@export_subgroup("Sneak")
@export var sneak_speed_modifier: float = 2
@export_subgroup("Blocking")
@export var shield_radius_protection: float = 90
@export var blocking_stamina_cost: int = 10
@export var broken_block_duration: float = 5

@export_category("Resources")
@export_subgroup("Health")
@export var max_health: float = 200
@export_enum("Health regeneration", "Health from potions") var health_type: String = "Health from potions"
@export var health_per_second: float = 10
@export var health_per_potion: float = 100

@export_subgroup("Stamina")
@export var max_stamina: float = 200
@export var stamina_per_second: float = 50

@export_subgroup("Mana")
@export var max_mana: float = 200
@export_enum("Mana regeneration", "Mana from potions") var mana_type: String = "Mana regeneration"
@export var mana_per_second: float = 10
@export var mana_per_potion: float = 100

@export_category("Camera")
@export_subgroup("Camera behaviour")
@export_range(0, 1) var camera_follow_speed: float

@export_subgroup("Camera Settings")
@export_range(-90, 0) var camera_angle: float = -45
@export var camera_height: float = 6
@export var camera_distance_from_player: float = 8

var stamina: float = max_stamina
var stamina_regen_cooldown: float = 0
var health: float = max_health
var mana: float = max_mana
var timer: float = 0
var is_sneaking: bool = false
var is_in_detection_area: bool = false
var is_in_hiding_area: bool = false
var is_blocking: bool = false
var block_broken: float = 0
var health_regen_delay: float = 0

var enemies_detecting_player: Array = []

var is_hidden: bool = false
var is_detected: bool = false

func _enter_tree():
	GlobalPlayer.set_player(self)

func _ready():
	get_child(2).rotation.x = camera_angle * PI / 180
	get_child(0).get_child(1).transform.origin.y = camera_height
	get_child(0).get_child(1).spring_length = camera_distance_from_player

func _physics_process(delta):
	resource_system(delta)
	check_detection()
	broken_block_tracker(delta)

func broken_block_tracker(delta):
	if block_broken > 0:
		block_broken -= delta

func resource_system(delta):
	if stamina_regen_cooldown > 0:
		stamina_regen_cooldown -= delta
	if health_regen_delay >= 0:
		health_regen_delay -= delta
	if timer >= 0.02:
		if health < max_health and health_type == "Health regeneration" and !is_detected and health_regen_delay <= 0:
			health += health_per_second/50
			if health > max_health:
				health = max_health
			health_changed.emit()
		if stamina < max_stamina and !is_blocking and stamina_regen_cooldown <= 0:
			stamina += stamina_per_second/50
			if stamina > max_stamina:
				stamina = max_stamina
			stamina_changed.emit()
		if mana < max_mana and mana_type == "Mana regeneration":
			mana += mana_per_second/50
			if mana > max_mana:
				mana = max_mana
			mana_changed.emit()
		timer = 0
	else:
		timer += delta

func add_detecting_enemy(enemy):
	if !enemies_detecting_player.has(enemy):
		enemies_detecting_player.append(enemy)

func remove_detecting_enemy(enemy):
	if enemies_detecting_player.has(enemy):
		enemies_detecting_player.erase(enemy)

func check_detection():
	if enemies_detecting_player.size() == 0:
		is_detected = false
	else:
		is_detected = true

func reduce_stamina(amount: int):
	stamina -= amount
	stamina_changed.emit()

##Reduces mana by set amount and returns true if player has enough mana, and false if they do not
func reduce_mana(amount: int):
	if mana >= amount:
		mana -= amount
		mana_changed.emit()
		return true
	else:
		return false

func set_sneaking(value: bool):
	is_sneaking = value

func set_stamina_regen_cooldown(value: float):
	stamina_regen_cooldown = value

func check_if_attack_was_blocked(attacker: Node3D, block_cost_modifier):
	var diff_vector = self.get_child(0).global_transform.origin - attacker.global_transform.origin
	var attack_angle = normalize_angle(atan2(diff_vector.x, diff_vector.z) / PI * 180)
	var player_angle = normalize_angle(self.get_child(0).get_child(0).rotation.y / PI * 180)
	if abs(attack_angle - player_angle) > 180:
		if attack_angle < player_angle:
			attack_angle += 360
		else:
			player_angle += 360
	if !(attack_angle >= player_angle - shield_radius_protection/2) or !(attack_angle <= player_angle + shield_radius_protection/2) or !is_blocking or block_broken > 0:
		return false
	if stamina < (blocking_stamina_cost * (1-block_cost_modifier)):
		block_broken = broken_block_duration
		print("Block was broken, stamina too low")
		return false
	PlayerActionTracker.attacks_blocked += 1
	return true

func normalize_angle(angle: float):
	if angle <= 0:
		return (angle + 360)
	return angle

func break_block():
	block_broken = broken_block_duration
	print("Block was broken from attack")

func take_damage(damage: int, attacker: Node3D, is_blockable, block_cost_modifier):
	if GameManager.get_having_i_frames():
		pass
	else:
		health_regen_delay = 2
		if check_if_attack_was_blocked(attacker, block_cost_modifier):
			if is_blockable:
				health -= damage* (1-get_blocking_damage_reduction())
				stamina -= blocking_stamina_cost * (1-block_cost_modifier)
				stamina_changed.emit()
				health_changed.emit()
				#$Controller/PlayerAudio/BlockedSFX.play()
			else: 
				break_block()
		else:
			health -= damage
			#$Controller/PlayerAudio/HitSFX.play()
			health_changed.emit()

func get_blocking_damage_reduction():
	if GameManager.get_first_weapon() == "Bow":
		return 0.4
	if GameManager.get_first_weapon() == "Staff":
		return 0.5
	if GameManager.get_first_weapon() == "Sword":
		if GameManager.get_second_weapon() == "Shield":
			return 1.0
		return 0.7
	if GameManager.get_first_weapon() == "Shield":
		return 1.0
	return 0.0

func heal(amount):
	if health <= max_health:
		health += amount
	health = clamp(health, 0, max_health)

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Bush"):
		is_in_hiding_area = true
		#$Controller/PlayerAudio/BushEntedSFX.play()
		
	if area.is_in_group("Enemy"):
		is_in_detection_area = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		is_in_detection_area = false
	if area.is_in_group("Bush"):
		is_in_hiding_area = false
		#$Controller/PlayerAudio/BushEntedSFX.play()
