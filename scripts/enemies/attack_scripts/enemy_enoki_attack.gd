extends Node3D

@export_group("Attack Stats")
@export var bullet_speed: int = 10
@export var bullet_damage: int = 10
@export var bullet_lifetime: float = 5
@export var attack_speed: float = 1/1.6667
@export_range(0, 1) var homing_strength: float = 0
@export var homing_range: float = 50

@export_subgroup("MeleeAttack")
@export var melee_damage: float = 20

var enemy
var player

var is_in_attack: bool = false
var in_melee_range: bool = false
var in_melee_damage_area: bool = false
var ranged_attack_delay: float = 0.54

var bullet_scene: PackedScene = preload("res://scenes/prefabs/enemies/enemy_bullet.tscn")

@onready var bullet_spawn_point = $BulletSpawnPoint
@onready var melee_sound = $MeleeSound
@onready var ranged_sound = $RangedSound

func _ready():
	player = GlobalPlayer.get_player()
	enemy = get_parent()

func _physics_process(delta):
	if enemy.state == enemy.States.MOVING:
		enemy.state = enemy.States.ATTACK_TYPE_1
	if !is_in_attack:
		attack_logic()
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)

func attack_logic():
	if enemy.state == enemy.States.ATTACK_TYPE_1 and !enemy.died:
		enemy.animation_player.pause()
		if enemy.slow_rotate_to_target(player.get_child(0)):
			if in_melee_range:
				melee_attack()
			elif enemy.detect_player_raycast(): 
				ranged_attack()

func ranged_attack():
	is_in_attack = true
	enemy.animation_player.speed_scale = 1
	enemy.animation_player.play("Throw")
	await get_tree().create_timer(0.54).timeout
	var pos: Vector3 = bullet_spawn_point.global_position 
	var vel: Vector3 = player.get_child(0).global_position - pos
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.set_parameter(player, bullet_damage, bullet_speed, homing_range, homing_strength, vel, bullet_lifetime)
	bullet.global_position = pos
	await get_tree().create_timer(1.6667 - 0.54).timeout
	enemy.state = enemy.States.NONE
	is_in_attack = false

func melee_attack():
	is_in_attack = true
	enemy.animation_player.speed_scale = 1
	enemy.animation_player.play("Punch")
	await get_tree().create_timer(1).timeout
	melee_sound.play()
	if in_melee_damage_area:
		player.take_damage(melee_damage, enemy, true, 0)
	await get_tree().create_timer(2.0833 - 1).timeout
	enemy.state = enemy.States.NONE
	is_in_attack = false

func _on_melee_attack_range_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_range = true

func _on_melee_attack_range_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_range = false

func _on_melee_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_damage_area = true

func _on_melee_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_damage_area = false
