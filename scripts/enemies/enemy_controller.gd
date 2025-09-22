extends CharacterBody3D

enum States {NONE, IDLE, ATTACK_TYPE_1, ATTACK_TYPE_2, MOVING, SEARCHING, PATROLLING, RETURNING}

@export_category("Stats")
@export_subgroup("Enemy Stats")
@export var health: int = 300

@export_group("Death Effect")
@export var has_death_animation: bool = true
@export var death_animation_name: String = "Die"
@export var death_animation_time: float = 0
@export var has_death_particles: bool = true
@export var death_particles_time: float = 3
@export var hitboxes: Array[Node]

var player

var state = States.NONE
var died: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_active: bool = true

@onready var model = $Model
@onready var animation_player = $Model/AnimationPlayer
@onready var death_spores = $DeathSpores

@onready var death_sound = $DeathSound
@onready var damage_sound = $DamageSound

func _ready():
	player = GlobalPlayer.get_player()

func die():
	GameManager.set_boss_puzzle()
	death_sound.play()
	for hitbox in hitboxes:
		hitbox.queue_free()
	if has_death_animation:
		animation_player.play("Die")
	await get_tree().create_timer(death_animation_time).timeout
	model.visible = false
	if has_death_particles: 
		death_spores.restart()
		death_spores.emitting = true
		await get_tree().create_timer(death_particles_time).timeout
	queue_free()
	
func detect_player_raycast():
	var space_state = get_world_3d().direct_space_state
	var origin = global_position
	var end = player.get_child(0).global_position 
	var query = PhysicsRayQueryParameters3D.create(origin, end, 7, [self])

	var result = space_state.intersect_ray(query)
	#Might need some adustment, crashes if the raycast never hits a collider
	if result != null:
		var collider = result.collider
		if collider is Node:
			if collider.is_in_group("Player"):
				return true
	return false

func take_damage(damage: int, type: String, has_knockback: bool = false, knockback_strenght: float = 0):
	health -= damage
	damage_sound.play()
	if health <= 0:
		died = true
		die()
		if type == "Bow":
			PlayerActionTracker.bow_kills += 1
		if type == "Staff":
			PlayerActionTracker.staff_kills += 1
		if type == "Sword":
			PlayerActionTracker.melee_kills += 1
	else:
		if has_knockback:
			var direction = (global_position - player.get_child(0).global_position).normalized()
			velocity += direction * knockback_strenght
		if state == States.IDLE or state == States.NONE or state == States.SEARCHING:
			state = States.SEARCHING
			get_child(0).get_pinged()

func slow_rotate_to_target(target):
	var angle_vector
	if type_string(typeof(target)) == "Vector3":
		angle_vector = target- global_position 
	else:
		angle_vector = target.global_position - global_position 
	var angle = limit_angle_in_degrees(atan2(angle_vector.x, angle_vector.z)  - PI/2)
	var yRotation = limit_angle_in_degrees(rotation.y)
	var angle_in_degrees = angle * 180 / PI
	var rotation_in_degrees = yRotation * 180 / PI
	
	if angle_in_degrees + 180 < rotation_in_degrees:
		rotation.y = lerp(yRotation, angle + 2*PI, 0.2)
	elif rotation_in_degrees + 180 < angle_in_degrees:
		rotation.y = lerp(yRotation + 2*PI, angle, 0.2)
	elif abs(angle_in_degrees - rotation_in_degrees) > 2:
		rotation.y = lerp(yRotation, angle, 0.2)
	if abs(angle_in_degrees - rotation_in_degrees) < 2:
		return true
	return false

func limit_angle_in_degrees(value: float):
	if value > PI:
		value -= 2*PI
	if value < -PI:
		value += 2*PI
	if value > PI or value < -PI:
		limit_angle_in_degrees(value)
	return value

func rotate_to_target(target):
	var angleVector
	if type_string(typeof(target)) == "Vector3":
		angleVector = target - global_position
	else:
		angleVector = target.global_position - global_position
	var angle = atan2(angleVector.x, angleVector.z)
	rotation.y = angle - PI/2
